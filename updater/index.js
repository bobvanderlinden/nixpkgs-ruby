#!/usr/bin/env node
const fs = require('mz/fs')
const path = require('path')
const fetch = require('node-fetch')
const nijs = require('nijs')

const rootPath = process.env.ROOT_PATH || process.cwd()

const naturalCompare = new Intl.Collator(undefined, {numeric: true, sensitivity: 'base'}).compare

async function mkdirp(directoryPath) {
  const parsedPath = path.parse(directoryPath)
  if (parsedPath.dir !== parsedPath.root) {
    await mkdirp(parsedPath.dir)
  }
  try {
    await fs.mkdir(directoryPath)
  } catch (e) {
    // Ignore error for already existing directory
    if (e.code !== 'EEXIST') {
      throw e
    }
  }
}

async function run() {
  const response = await fetch('https://raw.githubusercontent.com/postmodern/ruby-versions/master/ruby/checksums.sha256')
  const responseBody = await response.text()
  const regex = /^(\w+)  (ruby-((\d+)\.(\d+)\.(\d+)(?:-(\w+))?)\.tar\.gz)$/mg
  let match
  
  while ((match = regex.exec(responseBody)) !== null) {
    const sha256 = match[1]
    const filename = match[2]
    const versionName = match[3]
    const versionSegments = Array.prototype.slice.call(match, 4).filter(segment => segment !== undefined)
    const tarballUrl = `https://cache.ruby-lang.org/pub/ruby/${filename}`

    const versionPath = path.join(rootPath, path.join.apply(null, versionSegments))
    const versionJsonPath = path.join(versionPath, 'meta.nix')
    if (await fs.exists(versionJsonPath)) {
      continue
    }
    await mkdirp(versionPath)

    const content = {
      versionName,
      version: versionName.split(/\.|\-/g).concat(["", "", "", ""]).slice(0, 4),
      url: new nijs.NixURL(tarballUrl),
      sha256: sha256
    }
    await fs.writeFile(versionJsonPath, nijs.jsToIndentedNix(content, 0, true))

    while (versionSegments.length > 0) {
      await updateDerivationNix(path.join(rootPath, ...versionSegments))
      await updateDefaultNix(path.join(rootPath, ...versionSegments))
      versionSegments.pop()
    }
    await updateDerivationNix(rootPath)
    await updateDefaultNix(rootPath)
  }
}

async function updateDefaultNix(directoryPath) {
  const entities = await fs.readdir(directoryPath)
  const entitiesWithStats = await Promise.all(
    entities.map(entity =>
      fs.stat(path.join(directoryPath, entity))
        .then(stat => [entity, stat])
    )
  )
  const directories = entitiesWithStats
    .filter(([entity, stats]) => stats.isDirectory())
    .map(([entity, _]) => entity)
  
  const obj = {}
  for(let directory of directories) {
    obj[directory] = new nijs.NixImport(new nijs.NixFile({ value: `./${directory}` }))
  }
  if (directories.length > 0) {
    const latest = directories.sort(((a,b) => naturalCompare(b,a)))[0]
    obj['*'] = new nijs.NixImport(new nijs.NixFile({ value: `./${latest}` }))
  }
  if (await fs.exists(path.join(directoryPath, 'meta.nix'))) {
    obj['derivation'] = new nijs.NixFunInvocation({
      funExpr: new nijs.NixImport(
        new nijs.NixFile({ value: './derivation.nix' })
      ),
      paramExpr: new nijs.NixExpression('meta')
    });
    obj['meta'] = new nijs.NixImport(
      new nijs.NixFile({ value: './meta.nix' })
    )
  }

  await fs.writeFile(path.join(directoryPath, 'default.nix'), nijs.jsToIndentedNix(new nijs.NixRecursiveAttrSet(obj), 0, true))
}

async function updateDerivationNix(directoryPath) {
  const genericFilePath = path.join(directoryPath, 'derivation.nix')
  if (await fs.exists(genericFilePath)) {
    return
  }
  await fs.writeFile(genericFilePath, nijs.jsToIndentedNix(new nijs.NixImport(new nijs.NixFile({ value: '../derivation.nix' })), 0, true))
}

run()