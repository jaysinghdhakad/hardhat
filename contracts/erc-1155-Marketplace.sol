// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract My1155 is ERC1155 {
    constructor(string memory _uri) ERC1155(_uri) {
        _mint(msg.sender, 1, 10, "");
    }
}
