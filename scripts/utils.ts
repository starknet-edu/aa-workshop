import { Account, stark, ec, hash, CallData, RpcProvider, Contract, cairo } from 'starknet';
import {promises as fs} from 'fs';
import path from 'path';
import readline from 'readline';
import 'dotenv/config';

export async function waitForEnter(message: string): Promise<void> {
  return new Promise(resolve => {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });

    rl.question(message, _ => {
      rl.close();
      resolve();
    });
  });
};

export async function importChalk() {
  return import("chalk").then( m => m.default);
}

export function connectToStarknet() {
  return new RpcProvider({
    nodeUrl: process.env.RPC_ENDPOINT as string
  });
}

export function getDeployerWallet(provider: RpcProvider) {
  const privateKey = process.env.DEPLOYER_PRIVATE_KEY as string;
  const address = '0x011088d3cbe4289bc6750ee3a9cf35e52f4fa4e0ac9f42fb0b62e983139e135a';
  return new Account(provider, address, privateKey);
}

export function createKeyPair() {
  const privateKey = stark.randomAddress();
  const publicKey = ec.starkCurve.getStarkKey(privateKey);
  return {
    privateKey,
    publicKey,
  };
}

export async function getCompiledCode(filename: string) {
  const sierraFilePath = path.join(__dirname, `../target/dev/${filename}.contract_class.json`);
  const casmFilePath = path.join(__dirname, `../target/dev/${filename}.compiled_contract_class.json`);

  const code = [sierraFilePath, casmFilePath].map(async(filePath) => {
    const file = await fs.readFile(filePath);
    return JSON.parse(file.toString('ascii'));
  });

  const [sierraCode, casmCode] = await Promise.all(code);

  return {
    sierraCode,
    casmCode,
  };
}

interface DeclareAccountConfig {
  provider: RpcProvider;
  deployer: Account;
  sierraCode: any;
  casmCode: any;
}

export async function declareContract({provider, deployer, sierraCode, casmCode}: DeclareAccountConfig) {
  const declare = await deployer.declare({
    contract: sierraCode,
    casm: casmCode,
  });
  await provider.waitForTransaction(declare.transaction_hash);
}

interface DeployAccountConfig {
  privateKey: string;
  publicKey: string;
  classHash: string; 
  provider: RpcProvider;
}

export async function deployAccount({ privateKey, publicKey, classHash, provider }: DeployAccountConfig) {
  const chalk = await importChalk();

  const constructorArgs = CallData.compile({
    public_key: publicKey
  });

  const myAccountAddress = hash.calculateContractAddressFromHash(
    publicKey,
    classHash,
    constructorArgs,
    0
  );

  console.log(`Send ETH to address ${chalk.blue(chalk.bold(myAccountAddress))}`);
  const message = 'Press [Enter] when ready...';
  await waitForEnter(message);

  const account = new Account(provider, myAccountAddress, privateKey, "1");

  const deploy = await account.deployAccount({
    classHash: classHash,
    constructorCalldata: constructorArgs,
    addressSalt: publicKey,
  });

  await provider.waitForTransaction(deploy.transaction_hash);
  return deploy.contract_address;
}

interface TransferEthConfig {
  provider: RpcProvider;
  account: Account;
}

export async function transferEth({ provider, account }: TransferEthConfig) {
  const L2EthAddress = '0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7';

  const L2EthAbiPath = path.join(__dirname, './l2-eth-abi.json');
  const L2EthAbiFile = await fs.readFile(L2EthAbiPath);
  const L2ETHAbi = JSON.parse(L2EthAbiFile.toString('ascii'));

  const contract = new Contract(L2ETHAbi, L2EthAddress, provider);

  contract.connect(account);

  const recipient = '0x05feeb3a0611b8f1f602db065d36c0f70bb01032fc1f218bf9614f96c8f546a9';
  const amountInGwei = cairo.uint256(100);

  await contract.transfer(recipient, amountInGwei);
}