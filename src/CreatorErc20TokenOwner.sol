// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./BwitterErc20Voter.sol";
import "./ICreatorToken.sol";

contract CreatorErc20TokenOwner is BwitterErc20Voter {
    uint public votePercent = 51;
    uint public votePeriod = 60 * 60 * 24 * 7;

    function createProposalImpl(address erc20Address, bytes32 action) private {
        ICreatorToken ct = ICreatorToken(erc20Address);
        address creator = ct.creator();
        require(creator != address(0), "NO_CREATOR_AVAILABLE");
        require(msg.sender == creator, "INVALID_PROPOSAL_INITITOR");
        uint256[] memory settings = new uint256[](2);
        IERC20 erc20 = IERC20(erc20Address);
        uint validVotes = erc20.totalSupply();

        // exclude current contract balance
        validVotes = SafeMath.sub(validVotes, erc20.balanceOf(address(this)));

        if (creator != address(0)) {
            uint creatorBalance = erc20.balanceOf(creator);
            validVotes = SafeMath.sub(validVotes, creatorBalance);
        }
        
        settings[0] = SafeMath.mul(validVotes, votePercent);
        settings[0] = settings[0] / 100;
        settings[1] = block.timestamp + votePeriod;
        createProposal(erc20Address, action, settings);
    }

    function mint(address erc20Address, address to, uint256 amount) public {
        bytes32 action = "mint";
        if (!hasProposal(erc20Address, action)) {
            createProposalImpl(erc20Address, action);
        } else {
           if (multisig(erc20Address, action)) {
                deleteProposal(erc20Address, action);
                ICreatorToken ct = ICreatorToken(erc20Address);
                ct.mint(to, amount);
            }  
        }
    }
    
    function transfer(address erc20Address, address recipient, uint256 amount) public returns (bool) {
        bytes32 action = "transfer";
        if (!hasProposal(erc20Address, action)) {
            createProposalImpl(erc20Address, action);
        } else {
           if (multisig(erc20Address, action)) {
                deleteProposal(erc20Address, action);
                IERC20 token = IERC20(erc20Address);
                return token.transfer(recipient, amount);
            }  
        }
        
        return false;
    }

    function approve(address erc20Address, address spender, uint256 amount) public returns (bool) {
        bytes32 action = "approve";
        if (!hasProposal(erc20Address, action)) {
            createProposalImpl(erc20Address, action);
        } else {
           if (multisig(erc20Address, action)) {
                deleteProposal(erc20Address, action);
                IERC20 token = IERC20(erc20Address);
                return token.approve(spender, amount);
            }  
        }
        
        return false;
    }

    function transferOwnership(address erc20Address, address newOwner) public {
        bytes32 action = "transferOwnership";
        if (!hasProposal(erc20Address, action)) {
            createProposalImpl(erc20Address, action);
        } else {
            if (multisig(erc20Address, action)) {
               DaoVote storage vote = votes[erc20Address];
               uint voteBalance = SafeMath.add(vote.currentAgreedVote, vote.currentDisagreeVote);

               deleteProposal(erc20Address, action);
               IERC20 token = IERC20(erc20Address);
               uint balance = token.balanceOf(address(this));
               token.transfer(newOwner, SafeMath.sub(balance, voteBalance));

               Ownable ct = Ownable(erc20Address);
               ct.transferOwnership(newOwner);
            }  
        }
    }
}
