// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

///@notice Mock of Base Asset ERC20 contract
contract MockETH is ERC20 {

    constructor() ERC20("Mock ETH Token", "ETH") {
        //0xA8955d8243e652C702f4f964bfA02B669a515D5E is a test wallet
        _mint(address(0xA8955d8243e652C702f4f964bfA02B669a515D5E), 1000 * 10**18);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}