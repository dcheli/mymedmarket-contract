pragma solidity ^0.5.0;

contract MyMedMarket {
    address owner;
    
    enum ScriptStatus{ Authorized, Cancelled, Claimed, Countered, Released, Completed }
    
   struct Compound {
        string formula;
        bytes32 quantity;
        bytes32 form;
        bytes32 therapyClass;
    }

    struct Script {
        bytes32 scriptId;                   // keccak hash of drugName + now + scriptOwner address
        address owner;                      // owner of the script i.e. the consumer
        ScriptStatus status;
        Compound compound;
        uint price;                         // in pennies;this intitially represents the estimated market price, but changes to represent the final price
        bytes32 state;
        uint8 priceCounterOffersCount;
        mapping (address => Counter) priceCounterOffers;
        address[] pharmacyCounterOffers;    // this holds the address of pharmacies that submitted counter offers
        address pharmacy;                   // this is the ethereum address of the pharmacy that claims the script  
        address prescriber;                 // this is the ethereum address of the prescriber the wrote the script; not sure it's really relevant
        uint dateAdded;                     // timestamp that this script was added to the blockchain
        uint lastUpdateTime;                // timestamp that this script was last updated
    }
    
    struct Counter {
        bytes32 scriptId;
        uint price;
        uint expireTime;    
    }
    
    mapping (bytes32 => Script) allScripts;      // where all scripts exist
    uint public allScriptsCount;
    bytes32[] public marketPlaceScripts;                // where unclaimed scripts exist
    
    mapping (address => bytes32[]) pharmacyScripts;
    mapping (address => bytes32[]) consumerScripts;

    event ScriptAdded(address indexed _owner, bytes32 indexed _scriptId, bytes32 indexed _state);
    event ScriptClaimed(bytes32 indexed _scriptId, address indexed _pharmacy);
    event ScriptCountered(bytes32 indexed _scriptId, address indexed _consumer);
    
    constructor() public {
        owner = msg.sender;
        allScriptsCount = 0;
    }
    
    function addScript(string  memory formula,  bytes32 form, 
                    bytes32 quantity, bytes32 therapyClass, bytes32 state, 
                    address consumer, uint price ) public {
        require(form != bytes32(0), "Form is required.");
        require(quantity != bytes32(0), "Quantity is required.");
        require(state != bytes32(0), "State is required.");
        require(address(consumer) != address(0), "Consumer address is required.");
                
        bytes32 scriptId = keccak256(
             abi.encodePacked(formula, now, consumer));
        
        Compound memory compound = Compound({
            formula: formula,
            form: form,
            quantity: quantity,
            therapyClass: therapyClass
        });
        
        Script memory script = Script({
            scriptId: scriptId,
            owner: consumer,
            status: ScriptStatus.Authorized,
            compound: compound,
            price: price,
            state: state,
            priceCounterOffersCount: 0,
            //priceCounterOffers;
            pharmacyCounterOffers: new address[](0),
            pharmacy: address(0),
            prescriber:address(0),
            dateAdded: block.timestamp,
            lastUpdateTime: block.timestamp
        });

        // add to the allScripts mapping
        allScripts[scriptId] = script;
        allScriptsCount++;

        // add to the consumers storage
        consumerScripts[consumer].push(scriptId);
        
        // add to the marketPlaceScripts array
        marketPlaceScripts.push(scriptId);
        
        emit ScriptAdded(owner, scriptId, state);
    }

    function getMarketPlaceScriptCount() public view returns (uint count) {
        return(marketPlaceScripts.length);
    }
    
    function getMarketPlaceScript(uint index) public view 
        returns(bytes32 scriptId, ScriptStatus status, uint price, string memory formula,
        bytes32 form, bytes32 quantity, uint dateAdded, bytes32 state) {
            bytes32 id = marketPlaceScripts[index];
            Script memory script = allScripts[id];
           return(script.scriptId, script.status, script.price, script.compound.formula,
            script.compound.form, script.compound.quantity, script.dateAdded, script.state);
    }

    function getConsumerScriptsCount(address consumer) public view returns(uint count) {
        return(consumerScripts[consumer].length);
    }
    
    function getConsumerScript(address consumer, uint index ) public view
        returns(bytes32 scriptId, ScriptStatus status, uint price, string memory formula,
        bytes32 form, bytes32 quantity, uint8 priceCounterOffersCount,uint dateAdded) {
            bytes32 id = consumerScripts[consumer][index];
            Script memory script = allScripts[id];
            return(script.scriptId, script.status, script.price, script.compound.formula,
            script.compound.form, script.compound.quantity, 
            script.priceCounterOffersCount, script.dateAdded);
    } 
    
    function getPharmacyScriptCount(address pharmacy) view public returns (uint count) {
        return pharmacyScripts[pharmacy].length;
    }

   function getPharmacyScript(address pharmacy, uint index) public view returns(bytes32 scriptId, 
            ScriptStatus status, uint price,  string memory formula,
            bytes32 form, bytes32 quantity, uint dateAdded) {
                bytes32 id = pharmacyScripts[pharmacy][index];
                Script memory script = allScripts[id];
                return(script.scriptId, script.status, script.price, script.compound.formula,
                    script.compound.form, script.compound.quantity, script.dateAdded);
    }
    
    function cancelScript(address consumer, bytes32 scriptId ) public {
        Script storage script = allScripts[scriptId];
        
        require(address(script.owner) == address(consumer));
        require(script.status == ScriptStatus.Authorized ||
            script.status == ScriptStatus.Countered);
        
        script.status = ScriptStatus.Cancelled;
        script.lastUpdateTime = block.timestamp;
        // remove from marketplace
        removeFromMarketPlace(scriptId);
    }
    
    function claimScript(address pharmacy, bytes32 scriptId) public {
        Script storage script = allScripts[scriptId];
        require(script.status == ScriptStatus.Authorized);
        
        script.status = ScriptStatus.Claimed;
        script.pharmacy = pharmacy;
        pharmacyScripts[pharmacy].push(scriptId);
        removeFromMarketPlace(scriptId);
        emit ScriptClaimed(scriptId, pharmacy);
        
    }
    
    function releaseScript(address pharmacy, bytes32 scriptId) public {
        Script storage script = allScripts[scriptId];
        require(script.pharmacy == pharmacy);
        require(script.status == ScriptStatus.Claimed);

        // need to remove from the pharmacyScripts array
        for(uint i = 0; i < pharmacyScripts[pharmacy].length; i++) {
            if(pharmacyScripts[pharmacy][i] == scriptId) {
                if (i != pharmacyScripts[pharmacy].length - 1) {
                    pharmacyScripts[pharmacy][i] = pharmacyScripts[pharmacy][pharmacyScripts[pharmacy].length -1];
                }
                pharmacyScripts[pharmacy].length--;
                script.status = ScriptStatus.Authorized;
                marketPlaceScripts.push(scriptId);
                emit ScriptAdded(script.owner, scriptId, script.state);
                break;
            }
        }
    
    }

    function getPriceCounterCount(bytes32 scriptId) public view returns (uint count) {
        Script storage script = allScripts[scriptId];
        return script.priceCounterOffersCount;
    }
    
    function getPriceCounter(bytes32 scriptid, uint index) public view returns(bytes32 scriptId, address pharmacy, uint price, uint expireTime) {
        Script storage script = allScripts[scriptid];
        address pharmacyAddr = script.pharmacyCounterOffers[index];
        return(
            script.priceCounterOffers[pharmacyAddr].scriptId,
            pharmacyAddr,
            script.priceCounterOffers[pharmacyAddr].price,
            script.priceCounterOffers[pharmacyAddr].expireTime
        );
    }

    function counterScript(address pharmacy, bytes32 scriptId, uint price) public {
        bool pharmacyExists = false;
        Script storage script = allScripts[scriptId];
        require(script.status == ScriptStatus.Authorized || script.status == ScriptStatus.Countered);
        script.status = ScriptStatus.Countered;
        
        Counter memory counter = Counter({
           scriptId: scriptId,
           price: price,
           expireTime: block.timestamp + 86400
        });
        
        script.priceCounterOffersCount++;
        script.priceCounterOffers[pharmacy] = counter;
        for(uint8 i = 0; i < script.pharmacyCounterOffers.length; i++) {
            if(script.pharmacyCounterOffers[i] == pharmacy)
                pharmacyExists = true;
        }
        if(!pharmacyExists)
            script.pharmacyCounterOffers.push(pharmacy);
        script.lastUpdateTime = block.timestamp;
    }
    
    
    
    function approveCounter(address pharmacy, bytes32 scriptId ) public payable {
        // 1. pass in the winning scriptId and pharmacy address
        // 2. retrieve the counter from the script
        Script storage script = allScripts[scriptId];

        // 3. update the script.price with the winning price
        script.price = script.priceCounterOffers[pharmacy].price;

        // 4. marked the script as Claimed and indicate the pharmacy address
        
        script.status = ScriptStatus.Claimed;

        // 5. Give to the winning pharmacy and remove from market
        pharmacyScripts[pharmacy].push(scriptId);
        removeFromMarketPlace(scriptId);
        emit ScriptClaimed(scriptId, pharmacy);
    }
    
    function completeScript(address pharmacy, bytes32 scriptId) public {
        Script storage script = allScripts[scriptId];
        require(script.pharmacy == pharmacy);
        
        script.status = ScriptStatus.Completed;
    }
    
    
    function removeFromMarketPlace(bytes32 scriptId) private {
        
        for(uint i = 0; i < marketPlaceScripts.length; i++) {
            if(marketPlaceScripts[i] == scriptId) {
                if(i != marketPlaceScripts.length - 1) {
                    marketPlaceScripts[i] = marketPlaceScripts[marketPlaceScripts.length - 1];
                }
                marketPlaceScripts.length--;
                break;
            }
        }
    }
}