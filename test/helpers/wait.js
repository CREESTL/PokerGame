const chalk = require('chalk');

function sleep(millis) {
  return new Promise(resolve => setTimeout(resolve, millis));
}

function log(x) {
  process.stdout.write(chalk.yellow(x))
}

module.exports = async (secs) => {
  secs = secs || 1;
  log(`Sleeping for ${secs} second${secs === 1 ? '' : 's'}...`);
  await sleep(1000 * (secs || 1));
  log(' Slept.\n');
}
