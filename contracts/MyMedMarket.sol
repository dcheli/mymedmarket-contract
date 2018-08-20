pragma solidity ^0.4.24;

contract MyMedMarket {
    address owner;
    
    enum ScriptStatus{ Authorized, Cancelled, Claimed, Countered, Released, Completed }
    
    struct Drug {
        string drugName;
        bytes16 drugStrength;
        bytes16 drugForm;
        bytes16 drugQuantity;
        bytes32 therapyClass;
    }
    
    struct Script {
        bytes32 scriptId;                   // keccak hash of drugName + now + scriptOwner address
        address owner;                      // owner of the script i.e. the consumer
        ScriptStatus status;
        Drug drug;
        uint price;                         // in pennies;this intitially represents the estimated market price, but changes to represent the final price
        bytes2 state;
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
    
    mapping (bytes32 => Script) public allScripts;      // where all scripts exist
    uint public allScriptsCount;
    bytes32[] public marketPlaceScripts;                // where unclaimed scripts exist
    
    mapping (address => bytes32[]) pharmacyScripts;
    mapping (address => bytes32[]) consumerScripts;

    event ScriptAdded(address indexed _owner, bytes32 indexed _scriptId, bytes2 indexed _state);
    event ScriptClaimed(bytes32 indexed _scriptId, address indexed _pharmacy);
    event ScriptCountered(bytes32 indexed _scriptId, address indexed _consumer);
    
    constructor() public {
        owner = msg.sender;
        allScriptsCount = 0;
    }
    
    function addScript(string drugName, bytes16 drugStrength, bytes16 drugForm, 
                    bytes16 drugQuantity, bytes32 therapyClass, bytes2 state, 
                    address consumer, uint price ) public {
                        
        require(//keccak256(drugName) != keccak256("") &&
                drugStrength != 0 &&
                drugForm != 0 &&
                drugQuantity != 0 &&
                state != 0 &&
                consumer != 0 );
                
        bytes32 scriptId = keccak256(
             abi.encodePacked(drugName, now, consumer));
        
        Drug memory drug = Drug({
            drugName: drugName,
            drugStrength: drugStrength,
            drugForm: drugForm,
            drugQuantity: drugQuantity,
            therapyClass: therapyClass
        });
        
        Script memory script = Script({
            scriptId: scriptId,
            owner: consumer,
            status: ScriptStatus.Authorized,
            drug: drug,
            price: price,
            state: state,
            priceCounterOffersCount: 0,
            //priceCounterOffers;
            pharmacyCounterOffers: new address[](0),
            pharmacy: 0,
            prescriber:0,
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
    
    function getMarketPlaceScript(uint index) public view 
        returns(bytes32 scriptId, ScriptStatus status, uint price, string drugName) {
            bytes32 id = marketPlaceScripts[index];
            Script memory script = allScripts[id];
            return(script.scriptId, script.status, script.price, script.drug.drugName);
    }

    function getConsumerScriptsCount(address consumer) public view returns(uint count) {
        return(consumerScripts[consumer].length);
    }
    
    function getConsumerScript(address consumer, uint index ) public view
        returns(bytes32 scriptId, ScriptStatus status, uint price, string drugName,
        bytes16 drugStrength,  bytes16 drugForm, bytes16 drugQuantity, uint dateAdded) {
            bytes32 id = consumerScripts[consumer][index];
            Script memory script = allScripts[id];
            return(script.scriptId, script.status, script.price, script.drug.drugName,
                script.drug.drugStrength,  script.drug.drugForm, script.drug.drugQuantity, script.dateAdded);
    } 
    
    function cancelScript(address consumer, bytes32 scriptId ) public {
        Script storage script = allScripts[scriptId];
        
        require(script.owner == consumer);
        script.status = ScriptStatus.Cancelled;
        script.lastUpdateTime = block.timestamp;
        // remove from marketplace
        removeFromMarketPlace(scriptId);
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