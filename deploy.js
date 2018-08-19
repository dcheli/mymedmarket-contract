const HDWalletProvider = require('truffle-hdwallet-provider');
const Web3 = require('web3');
const compiledMyMedMarket = require('./build/MyMedMarket.json');

const provider = new HDWalletProvider(
    'blast chuckle twice police mountain uniform large slush artist seed evoke path',
    'https://rinkeby.infura.io/keHmED2MU9S8HnwbzGgG'
  );
  const web3 = new Web3(provider);

  const deploy = async () => {
    const accounts = await web3.eth.getAccounts();
    const count = await web3.eth.getTransactionCount(accounts[0]);
      
    console.log("getTransactionCount returns ", count);
    console.log('Attempting to deploy from account ', accounts[0]);
    console.log('Accounts contains ', accounts);

    const result = await new web3.eth.Contract(JSON.parse(compiledMyMedMarket.interface))
        .deploy({data: '0x' + compiledMyMedMarket.bytecode })
        .send({ gas: '4000000', from: accounts[0], gasPrice: '7000000000' });

        console.log("Address of contract is", result.options.address )
        //console.log("Be sure to include the address of the contract in your ethereuem/scriptHub.js file");      
  };

  deploy().catch((error) => {console.log("Error in deploy: ", error)});