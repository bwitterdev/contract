// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDao.sol";

interface IBwitterDao is IDao {
    function tokenOwnerApprove(uint tokenid, bytes32 whatFunction) external;

    function platformApprove(uint tokenid, bytes32 whatFunction) external;

    function proposalInitiator(uint tokenid, bytes32 whatFunction) external view returns (address);
}