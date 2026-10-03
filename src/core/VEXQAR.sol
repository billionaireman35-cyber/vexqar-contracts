pragma solidity 0.8.35;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract VEXQAR is ERC20, ERC20Permit {
    uint256 public constant MAX_SUPPLY = 121_000_000 * 10 ** 18;

    constructor(address initialHolder)
        ERC20("VEXQAR", "VXR")
        ERC20Permit("VEXQAR")
    {
        require(initialHolder != address(0), "VEXQAR: zero holder");
        _mint(initialHolder, MAX_SUPPLY);
    }
}
