//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Station.sol";

contract StationFactory {
    address public owner;
    address public kerosene;
    address[] public stationsRegistry;

    mapping (address => bool) public isStation;

    constructor (address _owner, address _kerosene) {
        owner = _owner;
        kerosene = _kerosene;
    }

    function changeOwner(address _newOwner) public {
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }

    function launchStation(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply
    ) public { 
        address station = address(new Station(_name, _symbol, address(this), _maxSupply, kerosene));
        stationsRegistry.push(station);
        isStation[station] = true;
        emit StationLaunched(_name, _symbol, address(this), _maxSupply, kerosene);
    }

    event StationLaunched(string _name, string _symbol, address _manufacturer, uint256 _maxSupply, address _kerosene);
    event OwnerChanged(address _newOwner);
}