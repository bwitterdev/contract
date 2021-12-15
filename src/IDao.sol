// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDao {
    function hasProposal(address tokenid, bytes32 whatFunction) external view returns (bool);

    function createProposal(address tokenid, bytes32 whatFunction, uint[] memory settings) external;

    function deleteProposal(address tokenid, bytes32 whatFunction) external;

    function multisig(address tokenid, bytes32 _whatFunction) external view returns (bool);
}