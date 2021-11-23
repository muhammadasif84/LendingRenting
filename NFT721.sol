// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "hardhat/console.sol";

contract NFT721 is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address contractAddress;

    struct NftDetails{
        address[] owners;
        uint256 creationTime;
    }
    mapping(uint256=>NftDetails) private _NftDetails;

    constructor(address marketplaceAddress) ERC721("MyNFTs", "METT") {
        contractAddress = marketplaceAddress;
    }

    function setNftDetails(uint256 _newItemId,address owner)private{
        _NftDetails[_newItemId].owners.push(owner);
        _NftDetails[_newItemId].creationTime=getTime();
    }

    function getNftDetails(uint256 _tokenId)public view returns(NftDetails memory){
        return _NftDetails[_tokenId];
    }

    function createToken(string memory tokenURI) public returns (uint) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        setNftDetails(newItemId,msg.sender);
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        setApprovalForAll(contractAddress, true);
        return newItemId;
    }
    //returns the total number of Nfts minted from this contract
    function totalSupply() public view returns(uint256){
        return _tokenIds.current();
    }

    function getTime() private view returns(uint256){
        return block.timestamp;
    }
}