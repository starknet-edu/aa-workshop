import { 
    hash,
    LibraryError,
    Account
} from 'starknet';

import {
    importChalk,
    connectToStarknet,
    getDeployerWallet,
    createKeyPair,
    getCompiledCode,
    declareContract,
    deployAccount,
    transferEth,
    isContractAlreadyDeclared,
} from './utils';

async function main() {  
  
    const chalk = await importChalk();
    const provider = connectToStarknet();
    const deployer = getDeployerWallet(provider);
    const { privateKey, publicKey } = createKeyPair();
    
    console.log(chalk.yellow('Account Contract:'));
    console.log(`Private Key = ${privateKey}`);
    console.log(`Public Key = ${publicKey}`);

    let sierraCode, casmCode;
    try {
        ({ sierraCode, casmCode } = await getCompiledCode('aa_Account'));
    } catch (error: any) {
        console.log(chalk.red('Failed to read contract files'));
        process.exit(1);
    }

    const classHash = hash.computeContractClassHash(sierraCode);
    const isAlreadyDeclared = await isContractAlreadyDeclared(classHash, provider)
    
    if (isAlreadyDeclared) {
        console.log(chalk.yellow('Contract class already declared'));
    } else {
        try {
            console.log('Declaring account contract...');
            await declareContract({ provider, deployer, sierraCode, casmCode });
            console.log(chalk.green('Account contract successfully declared'));
        } catch(error: any) {
            console.log(chalk.red('Declare transaction failed'));
            console.log(error);
            process.exit(1);
        }
    }
    
    console.log(`Class Hash = ${classHash}`);
    
    let address: string;
    try {
        console.log('Deploying account contract...');
        address = await deployAccount({ privateKey, publicKey, classHash, provider });
        console.log(chalk.green(`Account contract successfully deployed to Starknet testnet`));
    } catch(error: any) {
        if(error instanceof LibraryError && error.message.includes('balance is smaller')) {
            console.log(chalk.red('Insufficient account balance for deployment'));
            process.exit(1);
        } else {
            console.log(chalk.red('Deploy account transaction failed'));
            process.exit(1);
        }
    }

    const account = new Account(provider, address, privateKey, "1");

    try {
        console.log('Testing account by transferring ETH...');
        await transferEth({ provider, account });
        console.log(chalk.green(`Account works!`));
    } catch(error) {
        console.log(chalk.red('Failed to transfer ETH'));
        process.exit(1);
    }
}

main();