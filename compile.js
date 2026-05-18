import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'fs';
import solc from 'solc';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const contractPath = join(__dirname, 'contracts', 'PredictionMarket.sol');
const sourceCode = readFileSync(contractPath, 'utf8');

const input = {
  language: 'Solidity',
  sources: {
    'PredictionMarket.sol': {
      content: sourceCode,
    },
  },
  settings: {
    outputSelection: {
      '*': {
        '*': ['abi', 'evm.bytecode.object'],
      },
    },
  },
};

console.log('Compiling contract...');
const output = JSON.parse(solc.compile(JSON.stringify(input)));

if (output.errors) {
  output.errors.forEach((err) => console.error(err.formattedMessage));
  const hasErrors = output.errors.some(err => err.severity === 'error');
  if (hasErrors) process.exit(1);
}

const contract = output.contracts['PredictionMarket.sol']['PredictionMarket'];
const buildDir = join(__dirname, 'build');

if (!existsSync(buildDir)) {
  mkdirSync(buildDir);
}

writeFileSync(
  join(buildDir, 'PredictionMarket.abi.json'),
  JSON.stringify(contract.abi, null, 2)
);

writeFileSync(
  join(buildDir, 'PredictionMarket.bytecode.json'),
  JSON.stringify(contract.evm.bytecode.object)
);

console.log('Compilation successful!');
