pragma solidity ^0.4.24;
// Define a contract 'Supplychain'
import "../diamondaccesscontrol/CertifierRole.sol";
import "../diamondaccesscontrol/ConsumerRole.sol";
import "../diamondaccesscontrol/JewellerRole.sol";
import "../diamondaccesscontrol/MinerRole.sol";
import "../diamondcore/Ownable.sol";


contract SupplyChain  is CertifierRole, ConsumerRole, JewellerRole, MinerRole, Ownable {

  // Define 'owner'
  address owner;

  // Define a variable called 'upc' for Universal Product Code (UPC)
  uint  upc;

  // Define a variable called 'sku' for Stock Keeping Unit (SKU)
  uint  sku;

  // Define a public mapping 'items' that maps the UPC to an Item.
  mapping (uint => Diamond) diamonds;

  // Define a public mapping 'itemsHistory' that maps the UPC to an array of TxHash, 
  // that track its journey through the supply chain -- to be sent from DApp.
  mapping (uint => string[]) diamondsHistory;
  
  // Define enum 'State' with the following values:
  enum State 
  { 
    Mined,      // 0
    ForSale,    // 1  
    Sold,       // 2
    Polished,   // 3
    Certified,  // 4
    ForAuction, // 5
    Purchased   // 6
    }

  State constant defaultState = State.Mined;

  // Define a struct 'Item' with the following fields:
  struct Diamond {
    uint    sku;  // Stock Keeping Unit (SKU)
    uint    upc; // Universal Product Code (UPC), generated by the miner, goes on the package, can be verified by the certifier
    address ownerID;  // Metamask-Ethereum address of the current owner as the diamond moves through 8 stages
    address originMinerID; // Metamask-Ethereum address of the Miner
    string  originMinerName; // Miner Name
    string  diamondColor;  // Diamond Color
    string  diamondLength; // Diamond Length
    string  diamondWidth;  // Diamond Width
    string  diamondCarat;  // Diamond Carat
    uint    diamondID;  // Diamond ID potentially a combination of upc + sku
    string  diamondNotes; // Diamond Notes
    uint    diamondPrice; // Product Price
    State   itemState;  // Diamond State as represented in the enum above
    address jewellerID;  // Metamask-Ethereum address of the jeweller
    address certifierID; // Metamask-Ethereum address of the certifier
    address finalOwnerID; // Metamask-Ethereum address of the buyer
  }

  // Define 8 events with the same 8 state values and accept 'upc' as input argument
  event Mined(uint upc);
  event ForSale(uint upc);
  event Sold(uint upc);
  event Polished(uint upc);
  event Certified(uint upc);
  event ForAuction(uint upc);
  event Purchased(uint upc);

  // Define a modifer that checks to see if msg.sender == owner of the contract
  modifier onlyOwner() {
    require(msg.sender == owner, "this may not be owner");
    _;
  }

  // Define a modifer that verifies the Caller
  modifier verifyCaller (address _address) {
    require(msg.sender == _address, "checking caller"); 
    _;
  }

  // Define a modifier that checks if the paid amount is sufficient to cover the price
  modifier paidEnough(uint _price) { 
    require(msg.value >= _price, "msg value is less than price"); 
    _;
  }
  
  // Define a modifier that checks the price and refunds the remaining balance
  modifier checkValue(uint _upc) {
    _;
    uint _price = diamonds[_upc].diamondPrice;
    uint amountToReturn = msg.value - _price;
    diamonds[_upc].ownerID.transfer(amountToReturn);
  }

  // Define a modifier that checks if an item.state of a upc is mined
  modifier mined(uint _upc) {
    require(diamonds[_upc].itemState == State.Mined);
    _;
  }

  // Define a modifier that checks if an item.state of a upc is forSale
  modifier forSale(uint _upc) {
    require(diamonds[_upc].itemState == State.ForSale, "diamond is forsale");
    _;
  }
  
  // Define a modifier that checks if an item.state of a upc is sold
  modifier sold(uint _upc) {
    require(diamonds[_upc].itemState == State.Sold, "diamond is sold");
    _;
  }

  // Define a modifier that checks if an item.state of a upc is polished
  modifier polished(uint _upc) {
    require(diamonds[_upc].itemState == State.Polished);
    _;
  }

  // Define a modifier that checks if an item.state of a upc is certified
  modifier certified(uint _upc) {
    require(diamonds[_upc].itemState == State.Certified);
    _;
  }
  
  // Define a modifier that checks if an item.state of a upc is for auction
  modifier forAuction(uint _upc) {
    require(diamonds[_upc].itemState == State.ForAuction);
    _;
  }

  // Define a modifier that checks if an item.state of a upc is Purchased
  modifier purchased(uint _upc) {
    require(diamonds[_upc].itemState == State.Purchased);
    _;
  }

  // In the constructor set 'owner' to the address that instantiated the contract
  // and set 'sku' to 1
  // and set 'upc' to 1
  constructor() public payable {
    owner = msg.sender;
    sku = 1;
    upc = 1;
  }

  // Define a function 'kill' if required
  function kill() public {
    if (msg.sender == owner) {
      selfdestruct(owner);
    }
  }

  // Define a function 'mineDiamond' that allows a farmer to mark an item 'mined'
  function mineDiamond(uint _upc, address ownerID, address _originMinerID, string _originMinerName, string  _diamondColor, string  _diamondLength, string  _diamondWidth, string _diamondCarat, string _diamondNotes) public 
  {
    // Add the new item as part of mine
    
    Diamond memory newDiamond = Diamond( sku,_upc, ownerID, _originMinerID, _originMinerName,_diamondColor, _diamondLength, _diamondWidth,_diamondCarat, _upc+ sku, _diamondNotes,0,State.Mined, 0x0,0x0,0x0);

    // Increment sku
    sku = sku + 1;
    // Emit the appropriate event
    
    diamonds[_upc] = newDiamond;

    emit Mined(_upc);
  }

  // Define a function 'processtItem' that allows a farmer to mark an item 'Processed'
  function putRawDiamondForSale(uint _upc, uint _price) public mined(_upc)  onlyMiner() verifyCaller(diamonds[_upc].originMinerID)
  // Call modifier to check if upc has passed previous supply chain stage  
  // Call modifier to verify caller of this function  
  {
    // Update the appropriate fields
    diamonds[_upc].itemState = State.ForSale;
    diamonds[_upc].diamondPrice = _price;
        
    // Emit the appropriate event
    emit ForSale(_upc);
  }

  // Define a function 'buyItem' that allows the disributor to mark an item 'Sold'
  // Use the above defined modifiers to check if the item is available for sale, if the buyer has paid enough, 
  // and any excess ether sent is refunded back to the buyer
  function buyRawDiamond(uint _upc) public payable  forSale(_upc) paidEnough(msg.value)  checkValue(_upc) onlyJeweller()
    // Call modifier to check if upc has passed previous supply chain stage    
    // Call modifer to check if buyer has paid enough    
    // Call modifer to send any excess ether back to buyer    
    {
      // Update the appropriate fields - ownerID, distributorID, itemState
      diamonds[_upc].itemState = State.Sold;
      diamonds[_upc].ownerID = msg.sender;
      diamonds[_upc].jewellerID = msg.sender;
     
      // Transfer money to farmer
      diamonds[_upc].originMinerID.transfer(diamonds[_upc].diamondPrice);
    
      // emit the appropriate event
      emit Sold(_upc);
      
    }

  // Define a function 'sellItem' that allows a farmer to mark an item 'ForSale'
  function polishDiamond(uint _upc) public sold(_upc) onlyJeweller() verifyCaller(diamonds[_upc].jewellerID)
  // Call modifier to check if upc has passed previous supply chain stage  
  // Call modifier to verify caller of this function  
  {
    // Update the appropriate fields
      diamonds[_upc].itemState = State.Polished;
      //diamonds[_upc].ownerID = msg.sender;
     // diamonds[_upc].certifierID = msg.sender;
    
    // Emit the appropriate event
    emit Polished(_upc);
    
  }

  // Define a function 'buyItem' that allows the disributor to mark an item 'Sold'
  // Use the above defined modifiers to check if the item is available for sale, if the buyer has paid enough, 
  // and any excess ether sent is refunded back to the buyer
  function certifyDiamond(uint _upc) public polished(_upc) onlyCertifier() 
  // Call modifier to check if upc has passed previous supply chain stage  
  // Call modifier to verify caller of this function    
    {
      // Update the appropriate fields
      diamonds[_upc].itemState = State.Certified;
      diamonds[_upc].certifierID = msg.sender;
      // Emit the appropriate event    
      emit Certified(_upc);
    }

  // Define a function 'shipItem' that allows the distributor to mark an item 'Shipped'
  // Use the above modifers to check if the item is sold
  function addDiamondForAuction(uint _upc, uint _price) public certified(_upc)  onlyJeweller() verifyCaller(diamonds[_upc].jewellerID)
    // Call modifier to check if upc has passed previous supply chain stage    
    // Call modifier to verify caller of this function    
    {
      // Update the appropriate fields
      diamonds[_upc].itemState = State.ForAuction;
      diamonds[_upc].diamondPrice = _price;

      // Emit the appropriate event
      emit ForAuction(_upc);
    
    }

  // Define a function 'receiveItem' that allows the retailer to mark an item 'Received'
  // Use the above modifiers to check if the item is shipped
  function purchaseDiamond(uint _upc) public payable forAuction(_upc) paidEnough(msg.value)  checkValue(_upc) onlyConsumer()
    // Call modifier to check if upc has passed previous supply chain stage    
    // Access Control List enforced by calling Smart Contract / DApp
    {
    // Update the appropriate fields - ownerID, retailerID, itemState
    diamonds[_upc].itemState = State.Purchased;
    diamonds[_upc].ownerID = msg.sender;
    diamonds[_upc].finalOwnerID = msg.sender;

    diamonds[_upc].jewellerID.transfer(diamonds[_upc].diamondPrice);

    // Emit the appropriate event
    emit Purchased(_upc);

    
  }


  // Define a function 'fetchItemBufferOne' that fetches the data
  function fetchItemBufferOne(uint _upc) public view returns 
  (
  uint    itemSKU,
  uint    itemUPC,
  address ownerID,
  address originMinerID,
  string  diamondColor,    
  string  diamondLength,
  string  diamondWidth,    
  string  diamondCarat
  
  ) 
  {
  // Assign values to the 8 parameters
  
    itemSKU = diamonds[_upc].sku;
    itemUPC = diamonds[_upc].upc;
    ownerID = diamonds[_upc].ownerID;
    originMinerID = diamonds[_upc].originMinerID;
    diamondColor = diamonds[_upc].diamondColor;
    diamondLength = diamonds[_upc].diamondLength;
    diamondWidth = diamonds[_upc].diamondWidth;
    diamondCarat = diamonds[_upc].diamondCarat;

  return 
  (
  itemSKU,
  itemUPC,
  ownerID,
  originMinerID,
  diamondColor,    
  diamondLength,
  diamondWidth,    
  diamondCarat
  );
  }

  // Define a function 'fetchItemBufferTwo' that fetches the data
  function fetchItemBufferTwo(uint _upc) public view returns 
  (
  uint    itemSKU,
  uint    itemUPC,
  uint    diamondID,
  uint    diamondPrice,
  uint    itemState,
  string  diamondNotes,
  address jewellerID,
  address certifierID,
  address finalOwnerID
  ) 
  {
    // Assign values to the 9 parameters
    itemSKU = diamonds[_upc].sku;
    itemUPC = diamonds[_upc].upc;
    diamondID = diamonds[_upc].diamondID;
    diamondPrice = diamonds[_upc].diamondPrice;
    itemState = uint(diamonds[_upc].itemState);
    diamondNotes = diamonds[_upc].diamondNotes;
    jewellerID = diamonds[_upc].jewellerID;
    certifierID = diamonds[_upc].certifierID;
    finalOwnerID = diamonds[_upc].finalOwnerID;
 
    
  return 
  (
  itemSKU,
  itemUPC,
  diamondID,
  diamondPrice,  
  itemState,
  diamondNotes,
  jewellerID,
  certifierID,
  finalOwnerID
  );
  }
}
