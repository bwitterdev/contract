// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICreatorToken {
    function creator() external view returns(address);

    function mint(address to, uint256 amount) external; 

    function pause() external;

    function unpause() external;
}