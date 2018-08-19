const path = require('path');
const solc = require('solc');
const fs = require('fs-extra');

const buildPath = path.resolve(__dirname, 'build');
fs.removeSync(buildPath);   // deletes the build folder

const myMedMarketPath = path.resolve(__dirname, 'contracts', 'MyMedMarket.sol');
const source = fs.readFileSync(myMedMarketPath, 'utf8');

console.log("Starting to compile");
const output = solc.compile(source, 1).contracts;
console.log ("Compile Completed");

// checks to see if the folder exists and if not, it will create it
fs.ensureDirSync(buildPath);

// get each contract in the output and create a seperate file for it
for(let contract in output) {
    fs.outputJsonSync(
        path.resolve(buildPath, contract.replace(':', '') + '.json'), // the ':' replace is for windows OS only
        output[contract]
    )
}
