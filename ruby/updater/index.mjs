#!/usr/bin/env node
import { readFile, writeFile } from 'fs/promises'
import { join } from 'path'
import { pathToFileURL } from 'url'

const rootPath = process.env.ROOT_PATH || process.cwd()

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

const compareVersion = mapCompare(version => version.split('.'),
  listCompare(mapCompare(parseInt, descCompare(compareInt)))
)

async function writeJsonFile(filename, content) {
  await writeFile(filename, JSON.stringify(content, null, 2) + '\n');
}

async function readJsonFile(filename) {
  const content = await readFile(filename, { encoding: 'utf-8' });
  return JSON.parse(content);
}

Array.prototype.groupBy = function(keyFn) {
  return this.reduce((result, value) => {
    const key = keyFn(value);
    const bucket = result[key] = result[key] || [];
    bucket.push(value);
    return result;
  }, {});
};

Array.prototype.toObject = function() {
  return Object.fromEntries(this);
};

Object.prototype.entries = function() {
  return Object.entries(this);
};

Object.prototype.mapValues = function(mapFn) {
  return this.map(([key, value], index) => [key, mapFn(value, key, index)]);
}

Object.prototype.mapKeys = function(mapFn) {
  return this.map(([key, value], index) => [mapFn(key, value, index), value]);
}

Object.prototype.map = function(mapFn) {
  return Object.fromEntries(
    Object.entries(this).map(mapFn)
  );
}

function parseRssSources(responseBody) {
  return responseBody
    .split(/<item>/g)
    .slice(1)
    .map(item => {
      const tarballMatch = item.match(/https:\/\/cache\.ruby-lang\.org\/pub\/ruby\/(?<majorMinorVersion>\d+\.\d+)\/(?<filename>ruby-(?<version>\d+(?:\.\d+)+(?:-\w+)?)\.tar\.gz)(?=&quot;|<)/);
      const checksumMatch = item.match(/SHA256:\s*(?<checksum>[0-9a-f]{64})/i);

      if (!tarballMatch || !checksumMatch) {
        return null;
      }

      const { filename, version, majorMinorVersion } = tarballMatch.groups;
      const { checksum } = checksumMatch.groups;
      return [version, {
        url: `https://cache.ruby-lang.org/pub/ruby/${majorMinorVersion}/${filename}`,
        sha256: checksum.toLowerCase(),
      }];
    })
    .filter(Boolean)
    .toObject();
}

function buildAliases(sources) {
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
    latest: stableVersions[0],
    ...majorVersions,
    ...minorVersions,

    // Backwards compatibility.
    ...majorVersions.map(([major, version]) => [`${major}.*`, version]),
    ...minorVersions.map(([majorMinor, version]) => [`${majorMinor}.*`, version]),
  };

  return aliases;
}

export async function run({
  versionsPath = join(rootPath, 'versions.json'),
  fetch = globalThis.fetch,
} = {}) {
  const response = await fetch('https://www.ruby-lang.org/en/feeds/news.rss');
  if (!response.ok) {
    throw new Error(`Failed to fetch Ruby news RSS: ${response.status}`);
  }

  const responseBody = await response.text();
  const existingContent = await readJsonFile(versionsPath);
  const sources = {
    ...existingContent.sources,
    ...parseRssSources(responseBody),
  };
  const aliases = buildAliases(sources);

  await writeJsonFile(versionsPath, {
    sources,
    aliases
  });
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  await run();
}

export { buildAliases, parseRssSources };
