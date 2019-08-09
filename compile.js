const path = require('path');
const solc = require('solc');
const fs = require('fs-extra');

// Make sure that the build folder is deleted
const buildPath = path.resolve(__dirname, 'build');
fs.removeSync(buildPath);   

const myMedMarketPath = path.resolve(__dirname, 'contracts', 'MyMedMarket.sol');
console.log("Contract file is ", myMedMarketPath)
const source = fs.readFileSync(myMedMarketPath, 'utf8');

console.log("Starting to compile");


// solc 0.5 compiler documentation is here https://solidity.readthedocs.io/en/v0.5.3/using-the-compiler.html#
// Format the input for solc compiler:
const input = {
  language: 'Solidity',
  sources: {
    'MyMedMarket.sol': {
      content: source, // The imported content
    }
  },
  settings: {
    optimizer:{
      enabled: true,
      runs: 200
    },
    outputSelection: {
      '*': {
        '*': ['*']
      }
    }
  }
}; 

const output = JSON.parse(solc.compile(JSON.stringify(input)));

console.log(output);
console.log ("Compile Completed");

// checks to see if the folder exists and if not, it will create it
fs.ensureDirSync(buildPath);

// get each contract in the output and create a seperate file for it
for(let contract in output.contracts) {
  const contractName = contract.replace('.sol', '');
  console.log('Writing: ', contractName + '.json');
  fs.outputJsonSync(
    path.resolve(buildPath, contractName.replace(':', '') + '.json'), // the ':' replace is for windows OS only
    output.contracts[contract][contractName]
  )
}
