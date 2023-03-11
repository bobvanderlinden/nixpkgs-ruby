#!/usr/bin/env node
import { writeFile } from "fs/promises";
import { join } from "path";

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

Array.prototype.compact = function () {
  return this.filter((value) => value !== undefined && value !== null);
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

async function fetchText(url) {
  console.log(`Fetching ${url}...`);
  const response = await fetch(url);
  return await response.text();
}

async function* list(url) {
  const responseBody = await fetchText(url);
  const regex = /<a href="(?<path>[^"]+)">(?<name>.*)<\/a>/gm;
  for (const match of responseBody.matchAll(regex)) {
    yield {
      path: match.groups.path,
      name: match.groups.name,
    };
  }
}

const AsyncGenerator = (async function* () {})().constructor;

AsyncGenerator.prototype.map = async function* (mapFn) {
  for await (const value of this) {
    yield await mapFn(value);
  }
};

AsyncGenerator.prototype.filter = async function* (filterFn) {
  for await (const value of this) {
    if (await filterFn(value)) {
      yield value;
    }
  }
};

AsyncGenerator.prototype.flatMap = async function* (mapFn) {
  for await (const value of this) {
    for await (const subvalue of await mapFn(value)) {
      yield subvalue;
    }
  }
};

AsyncGenerator.prototype.toArray = async function () {
  const result = [];
  for await (const value of this) {
    result.push(value);
  }
  return result;
};

AsyncGenerator.prototype.toObject = async function () {
  return (await this.toArray()).toObject();
};

AsyncGenerator.prototype.compact = function () {
  return this.filter((value) => value !== undefined && value !== null);
};

AsyncGenerator.prototype.sort = async function* (compareFn) {
  const items = await this.toArray();
  yield* items.sort(compareFn);
};

AsyncGenerator.prototype.take = async function* (n) {
  let i = 0;
  for await (const value of this) {
    if (i >= n) {
      break;
    }
    yield value;
    i++;
  }
};

async function run() {
  const namedAliases = await list("https://nodejs.org/dist/")
    .flatMap(({ name, path }) => {
      const match =
        name.match(/^(?<alias>latest)\/$/) ??
        name.match(/^latest-(?<alias>.*)\/$/);
      return match ? [{ alias: match.groups.alias, path }] : [];
    })
    .flatMap(({ alias, path }) =>
      list(`https://nodejs.org/dist/${path}`)
        .flatMap(({ name }) => {
          const match = name.match(
            /^node-v(?<version>\d+\.\d+\.\d+)\.tar\.gz$/
          );
          return match ? [[alias, match.groups.version]] : [];
        })
        .take(1)
    )
    .toObject();

  const sources = await list("https://nodejs.org/dist/")
    .map(
      ({ path }) =>
        path.match(/^v(?<version>\d+\.\d+\.\d+)\/$/)?.groups?.version
    )
    .compact()
    .sort(compareVersion)
    .flatMap(async (version) => {
      const responseBody = await fetchText(
        `https://nodejs.org/dist/v${version}/SHASUMS256.txt`
      );
      const match =
        /^(?<sha256>\w{64})\s+(?<filename>node-v(?<version>\d+\.\d+\.\d+)\S*\.tar\.gz)$/gm.exec(
          responseBody
        );
      return match
        ? [
            [
              version,
              {
                url: `https://nodejs.org/dist/v${version}/${match.groups.filename}`,
                sha256: match.groups.sha256,
              },
            ],
          ]
        : [];
    })
    .toObject();

  const stableVersions = Object.keys(sources)
    .filter((version) => /^\d+\.\d+\.\d+$/.test(version))
    .sort(compareVersion);

  const majorVersions = stableVersions
    .groupBy((version) => /^\d+/.exec(version)[0])
    .mapValues((versions) => versions[0]);

  const minorVersions = stableVersions
    .groupBy((version) => /^\d+\.\d+/.exec(version)[0])
    .mapValues((versions) => versions[0]);

  const aliases = {
    ...namedAliases,
    ...majorVersions,
    ...minorVersions,
  };

  await writeJsonFile(join(rootPath, "versions.json"), {
    sources,
    aliases,
  });
}

run();
