#!/usr/bin/env node
import { writeFile } from 'fs/promises'
import { join } from 'path'

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

async function run() {
  const response = await fetch('https://raw.githubusercontent.com/postmodern/ruby-versions/master/ruby/checksums.sha256')
  const responseBody = await response.text()
  const regex = /^(?<checksum>\w+)  (?<filename>ruby-(?<version>(?<majorMinorVersion>\d+\.\d+)\.\d+(?:-(\w+))?)\.tar\.gz)$/mg
  
  const sources = [...responseBody.matchAll(regex)]
    .map(({ groups: { checksum, filename, version, majorMinorVersion }}) => [version, {
      url: `https://cache.ruby-lang.org/pub/ruby/${majorMinorVersion}/${filename}`,
      sha256: checksum
    }])
    .toObject();

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

  await writeJsonFile(join(rootPath, "versions.json"), {
    sources,
    aliases
  });
}

run()