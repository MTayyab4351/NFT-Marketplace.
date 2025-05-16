// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.19;




import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";



contract NFTMarketplace is ERC721,  ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private  _tokenIds;

  address public owner;
  uint public PlatformFee;
         constructor() ERC721("MyNFT", "MNFT")   {
         owner=msg.sender;
         PlatformFee=500;

       }

struct NFTdata {
\w
    string name;
    string symbol;
    string description;
    uint tokenId;
    address  payable seller;
    uint256 price;
    address buyer;
    bool soled;
  

}
mapping (uint256=>NFTdata) userNFTdata;

event NFTMinted(string  name,string symbol,string description,address owner,uint tokenId);
event NFTListed(uint price,uint tokenId);
event NFTPurchased(address buyer,uint tokenId,uint price,uint platformFee);
event NFTListingCancelled(uint indexed tokenId, address indexed seller);


struct  bidding{
        uint startTime;
        uint endTime;
        uint currentBid;
        uint highestBid;
        address highestBidder;


}

mapping(uint=>bidding) public  auctions;
event AuctionStarted(uint indexed tokenId, uint startTime, uint endTime);
event NewBidPlaced(uint indexed tokenId, address indexed bidder, uint bidAmount);
event AuctionEnded(uint indexed tokenId, address indexed winner, uint finalAmount);
event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);







modifier onlyOwner{
    require(owner==msg.sender,"only owner can call this function");
    _;
}



//Function for mint nft
     function mintNft(string memory _name,string memory _symbol, string memory _description) public {
         uint newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId);
        userNFTdata[newTokenId].name=_name;
        userNFTdata[newTokenId].symbol=_symbol;
        userNFTdata[newTokenId].description=_description;
        userNFTdata[newTokenId].seller=payable(msg.sender);
        userNFTdata[newTokenId].tokenId= _tokenIds.current();
        _tokenIds.increment();
    emit NFTMinted(  _name,_symbol,_description,msg.sender,newTokenId);    

     }





//Function for list nft
       function listNFT(uint _price,uint _tokenId) public {
        require(_price>0,"Price must be grater than 0");
        require(ownerOf(_tokenId)==msg.sender,"your not the owner of this nft");
        userNFTdata[_tokenId].seller=payable(msg.sender);
        userNFTdata[_tokenId].price=_price;
        userNFTdata[_tokenId].soled=false;
        emit NFTListed(_price,_tokenId);
        

       } 





//Function for buy nft and this function also charge platform fee
function buyNFT(uint _tokenId) public payable nonReentrant {
    NFTdata storage nft = userNFTdata[_tokenId];
    
    require(msg.value == nft.price, "Incorrect price");
    require(nft.soled == false, "Already sold");

    uint platformFeeAmount = (msg.value * PlatformFee) / 10000; // e.g., 500 = 5%
    uint sellerAmount = msg.value - platformFeeAmount;

    nft.seller.transfer(sellerAmount);
    payable(owner).transfer(platformFeeAmount);

    safeTransferFrom(nft.seller, msg.sender, _tokenId);

    nft.buyer = msg.sender;
    nft.soled = true;
    emit NFTPurchased(msg.sender,_tokenId,msg.value, platformFeeAmount);
}




//function for view nft
function getNFTdetails(uint _tokenId) public view returns(string memory name,string memory symbol,string memory desciption,uint tokenId,address seller, uint price) {
    NFTdata memory nft=userNFTdata[_tokenId];
           return (
            nft.name,
            nft.symbol,
            nft.description,
            nft.tokenId,
            nft.seller,
            nft.price

    );

}



//Function for cancle listing
function cancelListing(uint _tokenId) public {
    require(ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT");

    userNFTdata[_tokenId].price = 0;
    userNFTdata[_tokenId].seller = payable (address(0));
    userNFTdata[_tokenId].soled = false;
    emit NFTListingCancelled(_tokenId, msg.sender);
}

//Function to Resell an NFT after Purchase
function resellNFT(uint _tokenId, uint _price) public {
    require(ownerOf(_tokenId) == msg.sender, "You are not the owner");
    require(_price > 0, "Price must be greater than zero");
    NFTdata storage nft = userNFTdata[_tokenId];
    nft.price = _price;
    nft.soled = false;  // Mark it as available for sale
    nft.seller = payable(msg.sender);
    emit NFTListed(_price, _tokenId);
}





//Function to Fetch All Unsold NFTs



function fetchUnsoldNFTs() public view returns (NFTdata[] memory) {
    uint totalNFTs = _tokenIds.current();
    uint unsoldCount = 0;
for (uint i = 0; i < totalNFTs; i++) {
        if (userNFTdata[i].soled == false && userNFTdata[i].price > 0) {
            unsoldCount++;
        }
    }
  NFTdata[] memory unsoldNFTs = new NFTdata[](unsoldCount);
    uint index = 0;
for (uint i = 0; i < totalNFTs; i++) {
        if (userNFTdata[i].soled == false && userNFTdata[i].price > 0) {
            unsoldNFTs[index] = userNFTdata[i];
            index++;
        }
    }
       return unsoldNFTs;
}




//Function to check all nft that owner have
function fetchMyNFTs() public view returns (NFTdata[] memory) {
    uint totalNFTs = _tokenIds.current();
    uint count = 0;
for (uint i = 0; i < totalNFTs; i++) {
        if (ownerOf(i) == msg.sender) {
            count++;
        }
    }
    NFTdata[] memory myNFTs = new NFTdata[](count);
    uint index = 0;
for (uint i = 0; i < totalNFTs; i++) {
        if (ownerOf(i) == msg.sender) {
            myNFTs[index] = userNFTdata[i];
            index++;
        }
    }
     return myNFTs;
}


// Function to fetch all NFTs listed for sale by the caller
function fetchMyListedNFTs() public view returns (NFTdata[] memory) {
    uint totalNFTs = _tokenIds.current();
    uint count = 0;
for (uint i = 0; i < totalNFTs; i++) {
        if (userNFTdata[i].seller == msg.sender && userNFTdata[i].soled == false) {
            count++;
        }
    }
    NFTdata[] memory listedNFTs = new NFTdata[](count);
    uint index = 0;
for (uint i = 0; i < totalNFTs; i++) {
        if (userNFTdata[i].seller == msg.sender && userNFTdata[i].soled == false) {
            listedNFTs[index] = userNFTdata[i];
            index++;
        }
    }
     return listedNFTs;
}







// function for fetching all nft that are on auction
function getAllNFTsOnAuction() public view returns (NFTdata[] memory) {
    uint totalNFTs = _tokenIds.current(); // total minted NFTs
    uint count = 0;

    for (uint i = 0; i < totalNFTs; i++) {
        if (
            auctions[i].startTime != 0 &&
            block.timestamp >= auctions[i].startTime &&
            block.timestamp <= auctions[i].endTime
        ) {
            count++;
        }
    }

    NFTdata[] memory auctionedNFTs = new NFTdata[](count);
    uint index = 0;
    for (uint i = 0; i < totalNFTs; i++) {
        if (
            auctions[i].startTime != 0 &&
            block.timestamp >= auctions[i].startTime &&
            block.timestamp <= auctions[i].endTime
        ) {
            auctionedNFTs[index] = userNFTdata[i];
            index++;
        }
    }

    return auctionedNFTs;
}


}

contract auction is NFTMarketplace{




    // function for start auction  process
function auctionFunction(uint _tokenId,uint _timeInSecond) public {
   require(auctions[_tokenId].startTime == 0, "Auction already started");
   require(ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT");
          auctions[_tokenId].startTime=block.timestamp;
          auctions[_tokenId].endTime=block.timestamp + _timeInSecond;
          emit AuctionStarted(_tokenId, block.timestamp, block.timestamp + _timeInSecond);


         
          
}

    // function for start budding
    function biddingFunction(uint _tokenId) public payable {
        require(block.timestamp>=auctions[_tokenId].startTime && block.timestamp<=auctions[_tokenId].endTime,"the auction is not active");
        require(msg.value > auctions[_tokenId].highestBid, "Your bid must be higher");

        if (auctions[_tokenId].highestBidder != address(0)) {
    payable(auctions[_tokenId].highestBidder).transfer(auctions[_tokenId].highestBid);
}


        
        auctions[_tokenId].highestBid= msg.value;
        auctions[_tokenId].highestBidder=msg.sender;
        emit NewBidPlaced(_tokenId, msg.sender, msg.value);


            }        
            


    // function when auction end and transfer amout and nft  to owner and platformfee
    function endAuction(uint _tokenId) public {
    require(block.timestamp > auctions[_tokenId].endTime, "Auction not ended yet");

    address winner = auctions[_tokenId].highestBidder;
    uint amount = auctions[_tokenId].highestBid;
    uint platformFeeAmount = (amount * PlatformFee) / 10000;
    uint sellerAmount = amount - platformFeeAmount;
    payable(owner).transfer(platformFeeAmount);
    userNFTdata[_tokenId].seller.transfer(sellerAmount);
    safeTransferFrom(userNFTdata[_tokenId].seller, winner, _tokenId);
    userNFTdata[_tokenId].soled = true;
    userNFTdata[_tokenId].buyer = winner;
    emit AuctionEnded(_tokenId, winner, amount);
    emit OwnershipTransferred(owner, auctions[_tokenId].highestBidder);


}




// Function for view auction details
      function getAuctionDetails(uint _tokenId) public view returns (string memory nftName, string memory nftDescription,uint highestBid,uint remainingTime) {
                NFTdata memory nft = userNFTdata[_tokenId];
                bidding memory auctionData = auctions[_tokenId];
     uint timeLeft = 0;
            if (block.timestamp < auctionData.endTime) {
                    timeLeft = auctionData.endTime - block.timestamp;
                }
    return (nft.name,nft.description,auctionData.highestBid,timeLeft);
      
      
      
      
      
      
      }


}

