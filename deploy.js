import { readFileSync, writeFileSync } from 'fs';
import { ethers } from 'ethers';

const { DEPLOYER_PRIVATE_KEY } = JSON.parse(readFileSync('.deployer-env.json', 'utf8'));
const PRIVATE_KEY  = DEPLOYER_PRIVATE_KEY;
const RPC          = 'https://mainnet.base.org';
const CHAIN_ID     = 8453;
const NETWORK_NAME = 'Base';

async function main() {
  console.log(`Connecting to ${NETWORK_NAME}...`);
  const provider = new ethers.JsonRpcProvider(RPC, CHAIN_ID);
  const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

  const abi = JSON.parse(readFileSync('./build/PredictionMarket.abi.json', 'utf8'));
  const bytecode = JSON.parse(readFileSync('./build/PredictionMarket.bytecode.json', 'utf8'));

  console.log('Deploying PredictionMarket contract...');
  const factory = new ethers.ContractFactory(abi, bytecode, wallet);
  const contract = await factory.deploy();
  await contract.waitForDeployment();

  const address = await contract.getAddress();
  console.log(`Contract deployed at: ${address}`);

  const deploymentInfo = {
    contractAddress: address,
    network: NETWORK_NAME,
    chainId: CHAIN_ID,
    deployedAt: new Date().toISOString()
  };

  writeFileSync('deployment-info.json', JSON.stringify(deploymentInfo, null, 2));
  console.log('Deployment info saved to deployment-info.json');
}

main().catch(console.error);
