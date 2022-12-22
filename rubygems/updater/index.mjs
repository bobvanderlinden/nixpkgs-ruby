#!/usr/bin/env node
import { writeFile, readFile } from "fs/promises";
import { join } from "path";
import crypto from "crypto";

const rootPath = process.env.ROOT_PATH || process.cwd();

function mapCompare(mapFn, compareFn) {
  return (a, b) => compareFn(mapFn(a), mapFn(b));
}

function listCompare(compareFn) {
  return (a, b) => {
    const length = Math.min(a.length, b.length);
    for (let i = 0; i < length; i++) {
      const comparison = compareFn(a[i], b[i]);
      if (comparison !== 0) {
        return comparison;
      }
    }
    return a.length - b.length;
  };
}

function descCompare(compareFn) {
  return (a, b) => -compareFn(a, b);
}

function compareInt(a, b) {
  return a - b;
}

const compareVersion = mapCompare(
  (version) => version.split("."),
  listCompare(mapCompare(parseInt, descCompare(compareInt)))
);

async function writeJsonFile(filename, content) {
  await writeFile(filename, JSON.stringify(content, null, 2) + "\n");
}

Array.prototype.groupBy = function (keyFn) {
  return this.reduce((result, value) => {
    const key = keyFn(value);
    const bucket = (result[key] = result[key] || []);
    bucket.push(value);
    return result;
  }, {});
};

Array.prototype.toObject = function () {
  return Object.fromEntries(this);
};

Object.prototype.entries = function () {
  return Object.entries(this);
};

Object.prototype.mapValues = function (mapFn) {
  return this.map(([key, value], index) => [key, mapFn(value, key, index)]);
};

Object.prototype.mapKeys = function (mapFn) {
  return this.map(([key, value], index) => [mapFn(key, value, index), value]);
};

Object.prototype.map = function (mapFn) {
  return Object.fromEntries(Object.entries(this).map(mapFn));
};

async function fetchSriHash(url, type = "sha256") {
  const hash = crypto.createHash(type);
  const response = await fetch(url, { redirect: "follow" });
  if (!response.ok) {
    throw new Error(`Failed to fetch: ${url}`);
  }
  const reader = response.body.getReader();
  while (true) {
    const buffer = await reader.read();
    if (buffer.value) {
      hash.update(buffer.value);
    }
    if (buffer.done) {
      break;
    }
  }
  return `${type}-${hash.digest("base64")}`;
}

async function graphql({ url, headers, query, variables }) {
  const response = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${process.env.GITHUB_TOKEN}`,
      ...headers,
    },
    body: JSON.stringify({
      query,
      variables,
    }),
  });
  if (!response.ok) {
    throw new Error(`Failed to fetch graphql:\n${await response.text()}`);
  }
  return await response.json();
}
async function fetchReleasePage({ owner, repo, cursor }) {
  const result = await graphql({
    url: "https://api.github.com/graphql",
    query: `
      query ($owner: String!, $repo: String!, $cursor: String) {
        repository(owner: $owner, name: $repo) {
          releases(
            first: 100
            after: $cursor
            orderBy: {field: CREATED_AT, direction: DESC}
          ) {
            nodes {
              tagName
            }
            pageInfo {
              endCursor
              hasNextPage
            }
          }
        }
      }
    `,
    variables: { owner, repo, cursor },
  });
  return result.data.repository.releases;
}

async function* fetchReleases({ owner, repo }) {
  let cursor = null;
  while (true) {
    const page = await fetchReleasePage({ owner, repo, cursor });
    cursor = page.pageInfo.endCursor;
    for (const release of page.nodes) {
      yield release;
    }
    if (!page.pageInfo.hasNextPage) {
      break;
    }
  }
}

async function readJsonFile(path) {
  const content = await readFile(path, { encoding: 'utf-8' });
  return JSON.parse(content);
}

async function run() {
  const versionsPath = join(rootPath, 'versions.json');
  const existingContent = await readJsonFile(versionsPath);
  const sources = existingContent.sources;
  for await (const release of fetchReleases({
    owner: "rubygems",
    repo: "rubygems",
  })) {
    const tagName = release.tagName;
    const releaseNameMatch = /^v(\d+(?:\.\d+)*.*)$/.exec(tagName);
    if (!releaseNameMatch) {
      continue;
    }
    const releaseName = releaseNameMatch[1];

    console.log(releaseName);
    // When a release is already in sources, we may presume we have handled this release
    // in an earlier run. We may stop here.
    if (releaseName in sources) {
      continue;
    }

    const url = `https://github.com/rubygems/rubygems/archive/refs/tags/${tagName}.tar.gz`;
    const hash = await fetchSriHash(url);
    sources[releaseName] = {
      url,
      hash,
    };
  }
  
  const stableVersions = Object.keys(sources)
    .filter(version => /^\d+\.\d+\.\d+$/.test(version))
    .sort(compareVersion);

  const majorVersions = stableVersions
    .groupBy(version => /^\d+/.exec(version)[0])
    .mapValues(versions => versions[0]);
  
  const minorVersions = stableVersions
    .groupBy(version => /^\d+\.\d+/.exec(version)[0])
    .mapValues(versions => versions[0]);

  const aliases = {
    "": stableVersions[0],
    ...majorVersions,
    ...minorVersions,
    ...minorVersions.mapKeys(key => key.replace(/\./g, '_'))
  };

  await writeJsonFile(versionsPath, {
    sources,
    aliases
  });
}

run();
