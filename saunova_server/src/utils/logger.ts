const colors = {
  reset: "\x1b[0m",
  bright: "\x1b[1m",
  dim: "\x1b[2m",
  underscore: "\x1b[4m",

  fg: {
    red: "\x1b[31m",
    green: "\x1b[32m",
    yellow: "\x1b[33m",
    blue: "\x1b[34m",
    magenta: "\x1b[35m",
    cyan: "\x1b[36m",
    white: "\x1b[37m",
    gray: "\x1b[90m",
  },
};

export function logInfo(message: string, category: string = ""): void {
  console.log(
    `${colors.fg.green}[INFO]${colors.reset} [${colors.fg.cyan}${category}${colors.reset}] ${message}`
  );
}

export function logWarn(message: string, category: string = ""): void {
  console.warn(
    `${colors.fg.yellow}[WARN]${colors.reset} [${colors.fg.cyan}${category}${colors.reset}] ${message}`
  );
}

export function logError(error: unknown, category: string): void {
  console.error(
    `${colors.fg.red}[ERROR]${colors.reset} [${colors.fg.cyan}${category}${
      colors.reset
    }] ${error instanceof Error ? error.message : String(error)}`
  );
}

export function logDebug(message: string, category: string = ""): void {
  console.debug(
    `${colors.fg.magenta}[DEBUG]${colors.reset} [${colors.fg.cyan}${category}${colors.reset}] ${message}`
  );
}
