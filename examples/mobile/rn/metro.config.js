const path = require('path');
const { getDefaultConfig } = require('expo/metro-config');

const projectRoot = __dirname;
const dartBuildDir = path.resolve(projectRoot, '../build');
const nodeModulesDir = path.resolve(projectRoot, 'node_modules');

/** @type {import('metro-config').ConfigT} */
const config = getDefaultConfig(projectRoot);

// Allow Metro to watch and resolve the Dart build output that lives outside the RN app root.
config.watchFolders = [...(config.watchFolders || []), dartBuildDir];
config.resolver = {
  ...(config.resolver || {}),
  disableHierarchicalLookup: false,
  extraNodeModules: {
    ...(config.resolver?.extraNodeModules || {}),
    'react-native': path.join(nodeModulesDir, 'react-native'),
    react: path.join(nodeModulesDir, 'react'),
  },
};

module.exports = config;
