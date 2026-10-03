pragma solidity 0.8.35;

import {Test} from "forge-std/Test.sol";
import {VEXQAR} from "../../src/core/VEXQAR.sol";

contract VEXQARInvariantHandler is Test {
    VEXQAR public immutable token;
    address public immutable recipientA = address(0xA001);
    address public immutable recipientB = address(0xA002);

    constructor(VEXQAR _token) {
        token = _token;
    }

    function transfer(uint256 amount, bool toA) external {
        uint256 balance = token.balanceOf(address(this));

        if (balance == 0) {
            return;
        }

        amount = bound(amount, 0, balance);

        token.transfer(
            toA ? recipientA : recipientB,
            amount
        );
    }
}

contract VEXQARInvariantTest is Test {
    VEXQAR public token;
    VEXQARInvariantHandler public handler;

    uint256 internal constant EXPECTED_SUPPLY =
        121_000_000 * 10 ** 18;

    function setUp() public {
        token = new VEXQAR(address(this));
        handler = new VEXQARInvariantHandler(token);

        token.transfer(address(handler), EXPECTED_SUPPLY);

        targetContract(address(handler));
    }

    function invariant_TotalSupplyNeverChanges() public view {
        assertEq(token.totalSupply(), EXPECTED_SUPPLY);
    }

    function invariant_SupplyEqualsAllTrackedBalances() public view {
        uint256 trackedBalances =
            token.balanceOf(address(handler)) +
            token.balanceOf(handler.recipientA()) +
            token.balanceOf(handler.recipientB());

        assertEq(trackedBalances, EXPECTED_SUPPLY);
    }
}
