const Web3 = require('web3');
const Tx = require('ethereumjs-tx');


const options = {
  defaultAccount: '0xcaa482cdf28f1f06a59082f2289cbbb24e97b0fb',
  defaultBlock: 'latest',
  defaultGas: 1,
  defaultGasPrice: 0,
  transactionBlockTimeout: 50,
  transactionConfirmationBlocks: 2, // 24
  transactionPollingTimeout: 480
}
const web3 = new Web3('https://rinkeby.infura.io/v3/f4d34a220a7b44e7a7d80d7db1e3a034', null, options);
const privateKey1 =  Buffer.from('<private key goes here>', 'hex'); // add your private key

const compiledMyMedMarket = require('./build/MyMedMarket.json');
const account = web3.eth.defaultAccount;

// Deploy the contract

web3.eth.getTransactionCount(account, (err, txCount) => {
  const data = '0x' + compiledMyMedMarket.evm.bytecode.object;

  const txObject = {
    nonce:    web3.utils.toHex(txCount),
    gasLimit: web3.utils.toHex(5000000), // Raise the gas limit to a much higher amount
    gasPrice: web3.utils.toHex(web3.utils.toWei('10', 'gwei')),
    data: data
  }

  const tx = new Tx(txObject)
  tx.sign(privateKey1)

  const serializedTx = tx.serialize()
  const raw = '0x' + serializedTx.toString('hex')



  console.log("Deploying contract");
  web3.eth.sendSignedTransaction(raw)
  .on('error', function(error){ 
      console.log("An error occurred deploying contract ", error);
      console.log("Error message is ", error.message)})
  .then(function(receipt){
      console.log("Contract deployed successfully")
      console.log('Receipt is: ', receipt);
      console.log("Contract address is ", receipt.contractAddress);
  });
/*
  web3.eth.sendSignedTransaction(raw, (err, txHash) => {
    console.log('err:', err, 'txHash:', txHash)
    // Use this txHash to find the contract on Etherscan!
  })
  */
});
