pragma solidity ^0.8.10;
contract SenderContract {
    string value;

    constructor() {
        value = "Default";
    }

    function get() public view returns(string memory) {
    return value;
    }
    function set(string memory _value) public{
        value = _value;
    }
}