// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract my721 is ERC721 {
    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {
        _mint(msg.sender, 2);
        _mint(msg.sender, 3);
    }
}
