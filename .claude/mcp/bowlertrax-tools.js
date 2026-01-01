#!/usr/bin/env node
/**
 * BowlerTrax iOS Development MCP Server
 *
 * Provides tools for iOS development workflow automation:
 * - build_ios: Run xcodebuild for the project
 * - run_simulator: Launch app in iPad simulator
 * - run_device: Deploy to connected iPad
 * - swift_check: Syntax check Swift files
 * - list_simulators: List available iOS simulators
 * - open_xcode: Open project in Xcode
 * - clean_build: Clean derived data and rebuild
 * - read_specs: Read project specs for context
 */

const { spawn, execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const readline = require('readline');

// Project configuration
const PROJECT_ROOT = process.env.PROJECT_ROOT || '/Volumes/DevDrive/Projects/BowlerTrax-V1';
const IOS_DIR = path.join(PROJECT_ROOT, 'ios');
const ARCHIVE_DIR = path.join(PROJECT_ROOT, 'archive', 'react-native-build');

// MCP Protocol constants
const JSONRPC_VERSION = '2.0';

// Tool definitions
const TOOLS = [
  {
    name: 'build_ios',
    description: 'Build the BowlerTrax iOS project using xcodebuild. Supports Debug and Release configurations.',
    inputSchema: {
      type: 'object',
      properties: {
        configuration: {
          type: 'string',
          enum: ['Debug', 'Release'],
          default: 'Debug',
          description: 'Build configuration (Debug or Release)'
        },
        scheme: {
          type: 'string',
          default: 'BowlerTrax',
          description: 'Xcode scheme to build'
        },
        destination: {
          type: 'string',
          default: 'generic/platform=iOS Simulator',
          description: 'Build destination (e.g., "generic/platform=iOS Simulator" or specific device UDID)'
        }
      }
    }
  },
  {
    name: 'run_simulator',
    description: 'Launch BowlerTrax app in an iOS Simulator. Defaults to iPad Pro 12.9-inch.',
    inputSchema: {
      type: 'object',
      properties: {
        device: {
          type: 'string',
          default: 'iPad Pro 12.9-inch (6th generation)',
          description: 'Simulator device name'
        },
        boot: {
          type: 'boolean',
          default: true,
          description: 'Boot simulator if not running'
        }
      }
    }
  },
  {
    name: 'run_device',
    description: 'Deploy and run BowlerTrax on a connected iOS device (iPad).',
    inputSchema: {
      type: 'object',
      properties: {
        device_id: {
          type: 'string',
          description: 'Device UDID (optional, uses first connected device if not specified)'
        },
        configuration: {
          type: 'string',
          enum: ['Debug', 'Release'],
          default: 'Debug',
          description: 'Build configuration'
        }
      }
    }
  },
  {
    name: 'swift_check',
    description: 'Syntax check Swift files using swift compiler. Can check a single file or all Swift files in the ios directory.',
    inputSchema: {
      type: 'object',
      properties: {
        file: {
          type: 'string',
          description: 'Path to Swift file (optional, checks all if not specified)'
        },
        fix: {
          type: 'boolean',
          default: false,
          description: 'Attempt to auto-fix issues using SwiftFormat if available'
        }
      }
    }
  },
  {
    name: 'list_simulators',
    description: 'List all available iOS simulators with their states and UDIDs.',
    inputSchema: {
      type: 'object',
      properties: {
        filter: {
          type: 'string',
          description: 'Filter by device name (e.g., "iPad", "iPhone")'
        },
        booted_only: {
          type: 'boolean',
          default: false,
          description: 'Only show booted simulators'
        }
      }
    }
  },
  {
    name: 'open_xcode',
    description: 'Open the BowlerTrax project in Xcode.',
    inputSchema: {
      type: 'object',
      properties: {
        file: {
          type: 'string',
          description: 'Specific file to open (optional)'
        }
      }
    }
  },
  {
    name: 'clean_build',
    description: 'Clean derived data and rebuild the project from scratch.',
    inputSchema: {
      type: 'object',
      properties: {
        clean_derived_data: {
          type: 'boolean',
          default: true,
          description: 'Remove all derived data for the project'
        },
        rebuild: {
          type: 'boolean',
          default: true,
          description: 'Rebuild after cleaning'
        }
      }
    }
  },
  {
    name: 'read_specs',
    description: 'Read project specifications and context files for development reference.',
    inputSchema: {
      type: 'object',
      properties: {
        file: {
          type: 'string',
          enum: ['plan', 'progress', 'bowling-ref', 'claude', 'all'],
          default: 'all',
          description: 'Which spec file to read'
        }
      }
    }
  }
];

// Tool implementations
async function buildIOS(args) {
  const config = args.configuration || 'Debug';
  const scheme = args.scheme || 'BowlerTrax';
  const destination = args.destination || 'generic/platform=iOS Simulator';

  // Find xcodeproj or xcworkspace
  const workspacePath = findXcodeProject();
  if (!workspacePath) {
    return {
      success: false,
      error: 'No Xcode project found in ios/ directory. Create project first.',
      suggestion: 'Use Xcode to create a new iOS project in the ios/ directory.'
    };
  }

  const projectArg = workspacePath.endsWith('.xcworkspace')
    ? `-workspace "${workspacePath}"`
    : `-project "${workspacePath}"`;

  try {
    const cmd = `xcodebuild ${projectArg} -scheme "${scheme}" -configuration ${config} -destination "${destination}" build 2>&1`;
    const output = execSync(cmd, {
      cwd: IOS_DIR,
      maxBuffer: 10 * 1024 * 1024,
      encoding: 'utf8'
    });

    return {
      success: true,
      configuration: config,
      scheme: scheme,
      output: output.slice(-2000) // Last 2000 chars
    };
  } catch (error) {
    return {
      success: false,
      error: error.message,
      stderr: error.stderr?.slice(-2000) || '',
      stdout: error.stdout?.slice(-2000) || ''
    };
  }
}

async function runSimulator(args) {
  const device = args.device || 'iPad Pro 12.9-inch (6th generation)';
  const boot = args.boot !== false;

  try {
    // Get list of simulators
    const simList = execSync('xcrun simctl list devices available -j', { encoding: 'utf8' });
    const devices = JSON.parse(simList).devices;

    // Find matching device
    let targetDevice = null;
    let targetRuntime = null;

    for (const [runtime, deviceList] of Object.entries(devices)) {
      const found = deviceList.find(d => d.name.includes(device) || d.udid === device);
      if (found) {
        targetDevice = found;
        targetRuntime = runtime;
        break;
      }
    }

    if (!targetDevice) {
      return {
        success: false,
        error: `Simulator "${device}" not found`,
        available: Object.values(devices).flat().filter(d => d.name.includes('iPad') || d.name.includes('iPhone')).map(d => d.name)
      };
    }

    // Boot if needed
    if (boot && targetDevice.state !== 'Booted') {
      execSync(`xcrun simctl boot "${targetDevice.udid}"`, { encoding: 'utf8' });
    }

    // Open Simulator app
    execSync('open -a Simulator');

    // Install and launch app if built
    const appPath = findBuiltApp();
    if (appPath) {
      execSync(`xcrun simctl install "${targetDevice.udid}" "${appPath}"`, { encoding: 'utf8' });
      execSync(`xcrun simctl launch "${targetDevice.udid}" com.bowlertrax.app`, { encoding: 'utf8' });

      return {
        success: true,
        device: targetDevice.name,
        udid: targetDevice.udid,
        state: 'Running',
        appInstalled: true
      };
    }

    return {
      success: true,
      device: targetDevice.name,
      udid: targetDevice.udid,
      state: targetDevice.state === 'Booted' ? 'Already Running' : 'Booted',
      appInstalled: false,
      message: 'Simulator running. Build the app first to install.'
    };
  } catch (error) {
    return {
      success: false,
      error: error.message
    };
  }
}

async function runDevice(args) {
  try {
    // Check for ios-deploy
    try {
      execSync('which ios-deploy', { encoding: 'utf8' });
    } catch {
      return {
        success: false,
        error: 'ios-deploy not installed',
        suggestion: 'Install with: brew install ios-deploy'
      };
    }

    // List connected devices
    const deviceList = execSync('ios-deploy -c 2>&1 || true', { encoding: 'utf8' });

    if (!deviceList.includes('Found')) {
      return {
        success: false,
        error: 'No iOS devices connected',
        suggestion: 'Connect your iPad via USB and trust the computer'
      };
    }

    const appPath = findBuiltApp('iphoneos');
    if (!appPath) {
      return {
        success: false,
        error: 'No built app found for device',
        suggestion: 'Build for device first: build_ios with destination "generic/platform=iOS"'
      };
    }

    const deviceId = args.device_id || '';
    const deviceArg = deviceId ? `-i "${deviceId}"` : '';

    execSync(`ios-deploy ${deviceArg} --bundle "${appPath}" --debug`, {
      encoding: 'utf8',
      timeout: 120000
    });

    return {
      success: true,
      message: 'App deployed to device',
      appPath: appPath
    };
  } catch (error) {
    return {
      success: false,
      error: error.message
    };
  }
}

async function swiftCheck(args) {
  const results = [];

  try {
    // Check if swiftlint is available
    let hasSwiftLint = false;
    try {
      execSync('which swiftlint', { encoding: 'utf8' });
      hasSwiftLint = true;
    } catch {}

    if (args.file) {
      // Check specific file
      const filePath = path.isAbsolute(args.file) ? args.file : path.join(IOS_DIR, args.file);

      if (!fs.existsSync(filePath)) {
        return { success: false, error: `File not found: ${filePath}` };
      }

      try {
        execSync(`swiftc -parse "${filePath}" 2>&1`, { encoding: 'utf8' });
        results.push({ file: filePath, status: 'OK' });
      } catch (error) {
        results.push({ file: filePath, status: 'Error', errors: error.stdout || error.message });
      }

      if (hasSwiftLint) {
        try {
          const lintOutput = execSync(`swiftlint lint --path "${filePath}" 2>&1`, { encoding: 'utf8' });
          results[0].lint = lintOutput || 'No issues';
        } catch (error) {
          results[0].lint = error.stdout || error.message;
        }
      }
    } else {
      // Check all Swift files
      const swiftFiles = findSwiftFiles(IOS_DIR);

      if (swiftFiles.length === 0) {
        return {
          success: true,
          message: 'No Swift files found in ios/ directory',
          suggestion: 'Create Swift files in the ios/ directory to check'
        };
      }

      for (const file of swiftFiles.slice(0, 20)) { // Limit to 20 files
        try {
          execSync(`swiftc -parse "${file}" 2>&1`, { encoding: 'utf8' });
          results.push({ file: path.relative(PROJECT_ROOT, file), status: 'OK' });
        } catch (error) {
          results.push({
            file: path.relative(PROJECT_ROOT, file),
            status: 'Error',
            errors: (error.stdout || error.message).slice(0, 500)
          });
        }
      }
    }

    // Auto-fix if requested
    if (args.fix) {
      try {
        execSync('which swiftformat', { encoding: 'utf8' });
        execSync(`swiftformat "${IOS_DIR}" 2>&1`, { encoding: 'utf8' });
        results.push({ action: 'SwiftFormat applied' });
      } catch {
        results.push({ action: 'SwiftFormat not available', suggestion: 'brew install swiftformat' });
      }
    }

    const errorCount = results.filter(r => r.status === 'Error').length;

    return {
      success: errorCount === 0,
      filesChecked: results.filter(r => r.file).length,
      errors: errorCount,
      results: results
    };
  } catch (error) {
    return {
      success: false,
      error: error.message
    };
  }
}

async function listSimulators(args) {
  try {
    const output = execSync('xcrun simctl list devices available -j', { encoding: 'utf8' });
    const data = JSON.parse(output);

    const simulators = [];
    for (const [runtime, devices] of Object.entries(data.devices)) {
      // Extract iOS version from runtime string
      const match = runtime.match(/iOS[- ](\d+[.-]\d+)/);
      const iosVersion = match ? match[1].replace('-', '.') : runtime;

      for (const device of devices) {
        if (args.booted_only && device.state !== 'Booted') continue;
        if (args.filter && !device.name.toLowerCase().includes(args.filter.toLowerCase())) continue;

        simulators.push({
          name: device.name,
          udid: device.udid,
          state: device.state,
          isAvailable: device.isAvailable,
          iosVersion: iosVersion
        });
      }
    }

    // Sort by name
    simulators.sort((a, b) => a.name.localeCompare(b.name));

    return {
      success: true,
      count: simulators.length,
      simulators: simulators
    };
  } catch (error) {
    return {
      success: false,
      error: error.message
    };
  }
}

async function openXcode(args) {
  try {
    const projectPath = findXcodeProject();

    if (!projectPath) {
      // No project yet, open Xcode to create one
      execSync('open -a Xcode');
      return {
        success: true,
        message: 'Xcode opened. No project found - create new iOS project in ios/ directory.',
        projectDirectory: IOS_DIR
      };
    }

    if (args.file) {
      const filePath = path.isAbsolute(args.file) ? args.file : path.join(PROJECT_ROOT, args.file);
      execSync(`open -a Xcode "${filePath}"`);
      return {
        success: true,
        opened: filePath
      };
    }

    execSync(`open "${projectPath}"`);
    return {
      success: true,
      project: projectPath
    };
  } catch (error) {
    return {
      success: false,
      error: error.message
    };
  }
}

async function cleanBuild(args) {
  const results = [];

  try {
    if (args.clean_derived_data !== false) {
      // Find and remove derived data for this project
      const derivedDataPath = path.join(
        process.env.HOME,
        'Library/Developer/Xcode/DerivedData'
      );

      if (fs.existsSync(derivedDataPath)) {
        const dirs = fs.readdirSync(derivedDataPath);
        const bowlerTraxDirs = dirs.filter(d => d.startsWith('BowlerTrax'));

        for (const dir of bowlerTraxDirs) {
          const fullPath = path.join(derivedDataPath, dir);
          fs.rmSync(fullPath, { recursive: true, force: true });
          results.push({ cleaned: fullPath });
        }
      }

      // Also clean build folder in project
      const buildDir = path.join(IOS_DIR, 'build');
      if (fs.existsSync(buildDir)) {
        fs.rmSync(buildDir, { recursive: true, force: true });
        results.push({ cleaned: buildDir });
      }
    }

    if (args.rebuild !== false) {
      const buildResult = await buildIOS({ configuration: 'Debug' });
      results.push({ rebuild: buildResult });
    }

    return {
      success: true,
      results: results
    };
  } catch (error) {
    return {
      success: false,
      error: error.message,
      results: results
    };
  }
}

async function readSpecs(args) {
  const specs = {};
  const fileMap = {
    'plan': 'BowlerTrax-Plan.md',
    'progress': 'PROGRESS.md',
    'bowling-ref': 'Bowling-Info-Ref.md',
    'claude': 'CLAUDE.md'
  };

  const filesToRead = args.file === 'all' ? Object.keys(fileMap) : [args.file];

  for (const key of filesToRead) {
    const filename = fileMap[key];
    if (!filename) continue;

    const filePath = path.join(PROJECT_ROOT, filename);
    if (fs.existsSync(filePath)) {
      const content = fs.readFileSync(filePath, 'utf8');
      specs[key] = {
        path: filePath,
        content: content.slice(0, 10000) // Limit to 10KB per file
      };
    } else {
      specs[key] = { error: `File not found: ${filePath}` };
    }
  }

  return {
    success: true,
    specs: specs
  };
}

// Helper functions
function findXcodeProject() {
  if (!fs.existsSync(IOS_DIR)) return null;

  const files = fs.readdirSync(IOS_DIR);

  // Prefer workspace over project
  const workspace = files.find(f => f.endsWith('.xcworkspace'));
  if (workspace) return path.join(IOS_DIR, workspace);

  const project = files.find(f => f.endsWith('.xcodeproj'));
  if (project) return path.join(IOS_DIR, project);

  return null;
}

function findBuiltApp(platform = 'iphonesimulator') {
  const derivedDataPath = path.join(
    process.env.HOME,
    'Library/Developer/Xcode/DerivedData'
  );

  if (!fs.existsSync(derivedDataPath)) return null;

  const dirs = fs.readdirSync(derivedDataPath);
  const bowlerTraxDir = dirs.find(d => d.startsWith('BowlerTrax'));

  if (!bowlerTraxDir) return null;

  const productsPath = path.join(
    derivedDataPath,
    bowlerTraxDir,
    'Build/Products/Debug-' + platform
  );

  if (!fs.existsSync(productsPath)) return null;

  const apps = fs.readdirSync(productsPath).filter(f => f.endsWith('.app'));
  if (apps.length === 0) return null;

  return path.join(productsPath, apps[0]);
}

function findSwiftFiles(dir) {
  const results = [];

  if (!fs.existsSync(dir)) return results;

  const files = fs.readdirSync(dir, { withFileTypes: true });

  for (const file of files) {
    const fullPath = path.join(dir, file.name);

    if (file.isDirectory() && !file.name.startsWith('.')) {
      results.push(...findSwiftFiles(fullPath));
    } else if (file.isFile() && file.name.endsWith('.swift')) {
      results.push(fullPath);
    }
  }

  return results;
}

// MCP Protocol handlers
function handleInitialize(params) {
  return {
    protocolVersion: '2024-11-05',
    capabilities: {
      tools: {}
    },
    serverInfo: {
      name: 'bowlertrax-tools',
      version: '1.0.0'
    }
  };
}

function handleToolsList() {
  return {
    tools: TOOLS
  };
}

async function handleToolCall(params) {
  const { name, arguments: args } = params;

  const toolHandlers = {
    'build_ios': buildIOS,
    'run_simulator': runSimulator,
    'run_device': runDevice,
    'swift_check': swiftCheck,
    'list_simulators': listSimulators,
    'open_xcode': openXcode,
    'clean_build': cleanBuild,
    'read_specs': readSpecs
  };

  const handler = toolHandlers[name];
  if (!handler) {
    return {
      content: [{ type: 'text', text: JSON.stringify({ error: `Unknown tool: ${name}` }) }],
      isError: true
    };
  }

  try {
    const result = await handler(args || {});
    return {
      content: [{ type: 'text', text: JSON.stringify(result, null, 2) }]
    };
  } catch (error) {
    return {
      content: [{ type: 'text', text: JSON.stringify({ error: error.message }) }],
      isError: true
    };
  }
}

// MCP message processing
async function processMessage(message) {
  const { id, method, params } = message;

  let result;

  switch (method) {
    case 'initialize':
      result = handleInitialize(params);
      break;
    case 'tools/list':
      result = handleToolsList();
      break;
    case 'tools/call':
      result = await handleToolCall(params);
      break;
    case 'notifications/initialized':
      return null; // No response needed for notifications
    default:
      result = { error: { code: -32601, message: `Method not found: ${method}` } };
  }

  if (result === null) return null;

  return {
    jsonrpc: JSONRPC_VERSION,
    id: id,
    result: result
  };
}

// Main entry point - stdio transport
async function main() {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
    terminal: false
  });

  let buffer = '';

  rl.on('line', async (line) => {
    buffer += line;

    try {
      const message = JSON.parse(buffer);
      buffer = '';

      const response = await processMessage(message);
      if (response) {
        process.stdout.write(JSON.stringify(response) + '\n');
      }
    } catch (e) {
      // Incomplete JSON, wait for more data
      if (!(e instanceof SyntaxError)) {
        console.error('Error processing message:', e);
        buffer = '';
      }
    }
  });

  rl.on('close', () => {
    process.exit(0);
  });
}

main().catch(console.error);
