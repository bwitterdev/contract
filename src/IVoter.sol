// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDao.sol";

interface IVoter is IDao {
    function exists(address tokenid, bytes32 _whatFunction) external view returns(bool);

    function vote(address tokenid, bytes32 _whatFunction, uint agreed, uint disagreed) external;

    function unvote(address tokenid, bytes32 _whatFunction) external;
}