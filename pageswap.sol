// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev ERC721 token..
 */

contract pageSwap is ERC721URIStorage, Ownable {
    
    // struct Book includes all the attributes necessary for the book
    struct Book {
        address payable seller;     // seller address
        address buyer;              // buyer address
        string title;               // Title of the book
        string author;              // Author of the book
        uint price;                 // Price of the book
        bool sold;              
        bool orderPlaced;
    }

    uint private bookId;

    //Mapping from bookId to Book struct
    mapping(uint => Book) public books;


    mapping(uint => uint) public escrow;

    constructor() ERC721("pageSwap", "PGE") {}
    

       /**
     *  lists/stores the book with its details
     *  Done by the seller
     *  Seller has to deposit 2*price of the book
     */
    function listBook(string memory _title, string memory _author, uint _price) public payable {
        require(_price > 0, "Price must be greater than zero.");
        require(msg.value >= 2 * _price, "Deposit 2x book price.");
        
        Book storage newBook = books[++bookId];
        newBook.seller = payable(msg.sender);
        newBook.title = _title;
        newBook.author = _author;
        newBook.price = _price;
        newBook.sold = false;
        newBook.orderPlaced = false;
    }

     /**
     *  Buyer places order with bookId as parameter
     *  Has to depost 2* price of the book
     */

    function placeOrder(uint _bookId) public payable {
        require(_exists(_bookId), "Book does not exist.");
        require(!books[_bookId].sold, "Book already sold.");
        require(!books[_bookId].orderPlaced, "Order already placed.");
        require(msg.value == 2 * books[_bookId].price, "Send 2x book price to place the order.");
        
        books[_bookId].orderPlaced = true;
        books[_bookId].buyer = msg.sender;
        escrow[_bookId] = msg.value;
    }

     /**
     *  Buyer calls this function after the book is received
     *  The extra amount that is deposited will be returned to buyer and seller
     *  At the end he gets the NFT.
     */

    function orderReceived(uint _bookId) public {
        require(books[_bookId] > 0 ), "Book does not exist.");
        require(books[_bookId].orderPlaced, "Order not placed.");
        require(msg.sender == books[_bookId].buyer, "Only the buyer can confirm order received.");
        
        address payable seller = books[_bookId].seller;
        seller.transfer(books[_bookId].price);
        payable(msg.sender).transfer(books[_bookId].price);
        
        delete escrow[_bookId];
        books[_bookId].sold = true;
        
        _safeMint(msg.sender, _bookId);
        _setTokenURI(_bookId, tokenURI(_bookId));
    }
  

   // Might need to delete this function 
    
    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    function tokenURI(uint _tokenId) public view override returns (string memory) {
        require(books.exists(_tokenId), "Token does not exist.");
        Book memory book = books[_tokenId];
        string memory baseURI = "https://example.com/token/";
        return string(abi.encodePacked(baseURI, uint2str(_tokenId), "/", book.title));
    }
    
     function uint2str(uint _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}
