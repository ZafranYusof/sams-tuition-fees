const fs = require('fs');
const path = require('path');

const LOG_DIR = path.join(__dirname, '..', 'logs');

// Ensure logs directory exists
if (!fs.existsSync(LOG_DIR)) {
  fs.mkdirSync(LOG_DIR, { recursive: true });
}

const getTimestamp = () => new Date().toISOString();

const formatMessage = (level, message, meta) => {
  const base = `[${getTimestamp()}] [${level.toUpperCase()}] ${message}`;
  return meta ? `${base} ${JSON.stringify(meta)}` : base;
};

const writeToFile = (message) => {
  const date = new Date().toISOString().split('T')[0];
  const logFile = path.join(LOG_DIR, `${date}.log`);
  fs.appendFileSync(logFile, message + '\n');
};

exports.info = (message, meta) => {
  const formatted = formatMessage('info', message, meta);
  console.log(formatted);
  writeToFile(formatted);
};

exports.warn = (message, meta) => {
  const formatted = formatMessage('warn', message, meta);
  console.warn(formatted);
  writeToFile(formatted);
};

exports.error = (message, meta) => {
  const formatted = formatMessage('error', message, meta);
  console.error(formatted);
  writeToFile(formatted);
};

exports.debug = (message, meta) => {
  if (process.env.NODE_ENV === 'development') {
    const formatted = formatMessage('debug', message, meta);
    console.log(formatted);
  }
};
