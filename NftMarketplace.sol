// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;


import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./Auction.sol";


contract NftMarketplace is ReentrancyGuardUpgradeable {
    
  uint256 private tokenId;
    
  using Counters for Counters.Counter;
  Counters.Counter private _itemIds;
  Counters.Counter private _itemsRented;

  address payable owner;
  
  function initialize(address auctionContract)public initializer{
    owner = payable(msg.sender);
  }

  struct MarketItem {
    uint itemId;
    address nftContract;
    uint256 tokenId;
    address payable seller;
    address payable owner;
    uint256 price;
    bool sold;
    bool _isRent;
  }
  
  struct Rent{
      address tenant;
      uint256 totalTime;
      uint256 start;
  }
  
  mapping(address=> mapping(uint256=>bool)) private NFTexist;
  mapping(uint256 => MarketItem) private idToMarketItem;
  mapping(uint256 => Rent) private idToRent;
  

  event MarketItemCreated (
    uint indexed itemId,
    address indexed nftContract,
    uint256 indexed tokenId,
    address seller,
    address owner,
    uint256 price,
    bool sold,
    bool _isRent
  );

  
  /* Places an item for sale on the marketplace */
  function createMarketRentItem(
    address nftContract,
    uint256 tokenId,
    uint256 price,
    uint256 _seconds
  ) public payable nonReentrant {
    require(NFTexist[nftContract][tokenId] == false, "NFT already Exist on the market");
    require(price > 0, "Price must be at least 1 wei");
  //  require(msg.value == listingPrice, "Price must be equal to listing price");
    NFTexist[nftContract][tokenId] = true;
   
    _itemIds.increment();
    uint256 itemId = _itemIds.current();
    
    idToRent[itemId].totalTime = _seconds;
    
    idToMarketItem[itemId] =  MarketItem(
      itemId,
      nftContract,
      tokenId,
      payable(msg.sender),
      payable(address(0)),
      price,
      false,
      true
    );

    IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

    emit MarketItemCreated(
      itemId,
      nftContract,
      tokenId,
      msg.sender,
      address(0),
      price,
      false,
      true
    );
  }
  function createMarketRent(
    uint256 itemId
    ) public payable nonReentrant {
      uint price;
      uint tokenId = idToMarketItem[itemId].tokenId;
      address buyer;
    
    
    price = idToMarketItem[itemId].price;
    require(msg.value == price, "Please submit the asking price in order to complete the purchase");  
    
    idToRent[itemId].tenant = payable(msg.sender);
    idToRent[itemId].start = block.timestamp;
    idToMarketItem[itemId].seller.transfer(msg.value);
    
    

    
    _itemsRented.increment();
    
  }
  
  function updateRentCheck(uint256 itemId) public returns(bool){
      uint256 _endingUnix = idToRent[itemId].totalTime + idToRent[itemId].start;
      _endingUnix = _endingUnix * 1 seconds;
      if(_endingUnix > block.timestamp){
          return true;
      }
      else{
        idToRent[itemId].tenant = address(0);
        idToRent[itemId].start = 0;
        idToRent[itemId].totalTime = 0;
        return false;
      }
  }
  
  function play(uint256 itemId) public returns(bool){
      require(updateRentCheck(itemId) == true ,  "update func :: You are not the Authorized to play");
      require(idToRent[itemId].tenant == msg.sender , "address :: You are not the Authorized to play");
      return true;
  }
  

}
