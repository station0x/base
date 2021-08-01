//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
}

contract Marketplace {
    address public stationFactory;
    address public owner;
    address public kerosene;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    mapping(address => StationInfo) public stations;
    // collection => tokenId => Listing
    mapping(address => mapping(uint256 => Listing)) public listings;

    struct StationInfo {
        uint256 maxPrice;
        uint256 feePercent;
    }

    struct Listing {
        address payable seller;
        address station;
        uint256 price;
    }

    constructor(address _stationFactory, address _owner, address _kerosene) {
        stationFactory = _stationFactory;
        owner = _owner;
        kerosene = _kerosene;
        _status = _NOT_ENTERED;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Forbidden action");
        _;    
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    function changeOwner(address _newOwner) public {
        require(msg.sender == owner, "Do not call this function!");
        owner = _newOwner;
        emit ChangeOwner(_newOwner);
    }

    function registerStation(address _stationAddress, uint256 _maxPrice, uint256 _feePercent) public onlyOwner {
        stations[_stationAddress] = StationInfo(_maxPrice, _feePercent);
        emit RegisterStation(_stationAddress, _maxPrice, _feePercent);
    }

    function listToken(address _collection, uint256 _tokenId, address _stationAddress, uint256 _price) public nonReentrant {
        require(stations[_stationAddress].maxPrice > 0, "Station not registered");
        require(_price <= stations[_stationAddress].maxPrice, "Price exceeds station's max price");
        require(_price > 0, "Price must be larger than Zero");
        require(listings[_collection][_tokenId].price != 0, "Token is already listed");
        
        listings[_collection][_tokenId] = Listing(payable(msg.sender), _stationAddress, _price);
        require(IERC721(_collection).getApproved(_tokenId) == address(this));
        emit ListToken(_collection, _tokenId, _stationAddress, _price);
    }

    function buyToken(address _collection, uint256 _tokenId) public payable nonReentrant {
        Listing memory thisListing = listings[_collection][_tokenId];
        require(msg.value > 0, "Unmatched Price: Can't be Zero");
        require(thisListing.price == msg.value, "Unmatched Price");

        IERC721(_collection).safeTransferFrom(thisListing.seller, msg.sender, _tokenId);
        uint256 fee;
        uint256 feePercent = stations[thisListing.station].feePercent;
        if(feePercent > 0) {
            fee = msg.value * 10000 / feePercent;
            thisListing.seller.transfer(thisListing.price);
            // Send fees to stations (make station payable)
            // this.Listing.station.transfer(fee)
        }
        thisListing.seller.transfer(thisListing.price - fee);
        emit BuyToken(_collection, _tokenId);
    }

    event ChangeOwner(address _newOwner);
    event RegisterStation(address _stationAddress, uint256 _maxPrice, uint256 _feePercent);
    event ListToken(address _collection, uint256 _tokenId, address _stationAddress, uint256 _price);
    event BuyToken(address _collection, uint256 _tokenId);
}