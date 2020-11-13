pragma solidity ^0.4.15;


interface GasTokenInterface {
    function freeUpTo(uint256 value) public returns (uint256 freed);

    function freeFromUpTo(address from, uint256 value) public returns (uint256 freed);

    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function approve(address spender, uint256 value) public returns (bool success);
}
