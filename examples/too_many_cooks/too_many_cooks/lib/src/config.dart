/// Configuration for Too Many Cooks MCP server.
///
/// Pure re-export from too_many_cooks_data. All database path resolution
/// lives in the data package to guarantee a single source of truth.
library;

import 'package:too_many_cooks_data/too_many_cooks_data.dart'
    show TooManyCooksDataConfig;

export 'package:too_many_cooks_data/too_many_cooks_data.dart'
    show
        TooManyCooksDataConfig,
        createDataConfig,
        createDataConfigFromWorkspace,
        defaultConfig,
        getWorkspaceFolder,
        resolveDbPath;

/// Server configuration type alias for backwards compatibility.
typedef TooManyCooksConfig = TooManyCooksDataConfig;
