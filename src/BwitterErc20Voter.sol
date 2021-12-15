// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// import "./IVoter.sol";

contract BwitterErc20Voter is /* IVoter, */ Ownable {
    struct DaoVote {
        address tokenid;
        bytes32 proposal;
        uint minimumAgreedVote;
        uint endtime;
        uint currentAgreedVote;
        uint currentDisagreeVote;
        address initiator;
    }

    mapping(address => DaoVote) public votes;
    mapping(address => mapping(address => uint)) private _locked_token_for_votes;

    event VoteProposalCreated(address indexed tokenid, bytes32 proposal, address initiator, uint minimumAgreedVote, uint endtime);

    event VoteProposalDeleted(address indexed tokenid, address initiator);

    event ProposalVoted(address indexed tokenid, bytes32 proposal, address approver, uint agreed, uint disagreed);

    function hasProposal(address tokenid, bytes32 whatFunction) public view returns (bool) {
        DaoVote storage dvote = votes[tokenid];
        return dvote.tokenid == tokenid && dvote.proposal == whatFunction;
    }

    function createProposal(
        address tokenid, bytes32 whatFunction, uint[] memory settings) public {
        address initiator = msg.sender;
        // TODO: need access check
        // require(initiator == Ownable(tokenid).owner(), "VOTER_INVALID_VOTE_INITIATOR");

        DaoVote storage dvote = votes[tokenid];
        require(dvote.tokenid == address(0), "VOTER_HAS_VOTE");
        dvote.tokenid = tokenid;
        dvote.proposal = whatFunction;
        dvote.minimumAgreedVote = settings[0];
        dvote.endtime = settings[1];
        dvote.initiator = initiator;

        emit VoteProposalCreated(tokenid, whatFunction, initiator, settings[0], settings[1]);
    }

    function vote(address tokenid, bytes32 whatFunction, uint agreed, uint disagreed) public {
        DaoVote storage dvote = votes[tokenid];
        require(dvote.tokenid != address(0), "VOTER_NO_VOTE");
        require(dvote.proposal == whatFunction, "VOTER_MISMATCH_VOTE");

        IERC20 erc20Token = IERC20(tokenid);
        uint balance = erc20Token.balanceOf(msg.sender);
        uint amount = SafeMath.add(agreed, disagreed);
        require(balance >= amount, "VOTER_NOT_ENOUGH_VOTE");

        erc20Token.transferFrom(msg.sender, address(this), amount);
        dvote.currentAgreedVote = SafeMath.add(dvote.currentAgreedVote, agreed);
        dvote.currentDisagreeVote = SafeMath.add(dvote.currentDisagreeVote, disagreed);
        _locked_token_for_votes[tokenid][msg.sender] = 
            SafeMath.add(_locked_token_for_votes[tokenid][msg.sender], amount);

        emit ProposalVoted(tokenid, whatFunction, msg.sender, agreed, disagreed);
    }
    
    function exists(address tokenid, bytes32) public view returns(bool) {
        DaoVote storage dvote = votes[tokenid];
        return dvote.tokenid != address(0);
    }

    function myvote(address tokenid) public view returns(uint) {
        return _locked_token_for_votes[tokenid][msg.sender];
    }

    function unvote(address tokenid, bytes32) public {
        DaoVote storage dvote = votes[tokenid];

        if (dvote.tokenid != address(0)) {
            require(block.timestamp >= dvote.endtime, "VOTER_VOTE_NOT_END");
        }

        uint amount = _locked_token_for_votes[tokenid][msg.sender];
        require(amount > 0, "VOTER_NO_VOTE");
        _locked_token_for_votes[tokenid][msg.sender] = 0;
        if (amount > 0) {
            IERC20 erc20Token = IERC20(tokenid);
            erc20Token.transfer(msg.sender, amount);
        }
    }

    function multisig(address tokenid, bytes32) public view returns (bool) {
        DaoVote storage dvote = votes[tokenid];
        require(dvote.tokenid != address(0), "VOTER_NO_VOTE");

        return dvote.currentAgreedVote > dvote.currentDisagreeVote && dvote.currentAgreedVote >= dvote.minimumAgreedVote;
    }

    function deleteProposal(address tokenid, bytes32 /* whatFunction */) public {
        DaoVote storage dvote = votes[tokenid];
        require(dvote.tokenid != address(0), "VOTER_NO_VOTE");
        require(msg.sender == dvote.initiator || 
                msg.sender == owner(), "VOTER_INVALID_OWNER");
        delete votes[tokenid];

        emit VoteProposalDeleted(tokenid, msg.sender);
    }

    function lastResort(address tokenid, address recipient) public onlyOwner {
        uint amount = _locked_token_for_votes[tokenid][recipient];
        _locked_token_for_votes[tokenid][recipient] = 0;
        if (amount > 0) {
            IERC20 erc20Token = IERC20(tokenid);
            erc20Token.transfer(recipient, amount);
        }
    }
}