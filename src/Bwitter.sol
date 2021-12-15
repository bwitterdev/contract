// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Bwitter is ERC20Burnable, ERC20Pausable, Ownable {
    address public creator;
    uint public maxSupply;

    constructor (uint initialSupply_, uint maxSupply_) ERC20("Bwitter", "BT") {
        require(maxSupply_ >= initialSupply_, "MAX_LESS_THAN_INITIAL");
        _mint(msg.sender, initialSupply_);
        creator = msg.sender;
        maxSupply = maxSupply_;
    }

    function setCreator(address value) public onlyOwner {
        creator = value;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(SafeMath.add(totalSupply(), amount) <= maxSupply, "BT_EXCEED_MAXSUPPLY");
        _mint(to, amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}
