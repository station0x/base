//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Registry {
    address gameMaster;
    mapping (string => address) public addressOf;

    constructor(address _gameMaster) {
        gameMaster = _gameMaster;
    }

    function getAddressOf(string calldata name) public view returns(address) {
        return addressOf[name];
    }

    function setAddressOf(string calldata name, address nameAddress) public {
        require(msg.sender == gameMaster);
        addressOf[name] = nameAddress;
        emit SetAddressOf(name, nameAddress);

    }

    function changeGameMaster(address _newGameMaster) public {
        require(msg.sender == gameMaster);
        gameMaster = _newGameMaster;
        emit ChangeGameMaster(_newGameMaster);
    }

    event SetAddressOf(string indexed name, address nameAddress);
    event ChangeGameMaster(address _newGameMaster);
}