pragma solidity 0.8.35;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {VEXQAR} from "../../src/core/VEXQAR.sol";
import {VEXQARLinearVesting} from "../../src/vesting/VEXQARLinearVesting.sol";

contract VEXQARLinearVestingTest is Test {
    VEXQAR public token;
    VEXQARLinearVesting public vesting;

    address internal constant BENEFICIARY = address(0xBEEF);

    uint256 internal constant ALLOCATION = 1_000_000 * 10 ** 18;
    uint256 internal constant START = 1_000_000;
    uint256 internal constant CLIFF = 365 days;
    uint256 internal constant DURATION = 1095 days;

    function setUp() public {
        token = new VEXQAR(address(this));

        vesting = new VEXQARLinearVesting(
            token,
            BENEFICIARY,
            ALLOCATION,
            START,
            CLIFF,
            DURATION
        );

        token.transfer(address(vesting), ALLOCATION);
    }

    function test_ConstructorValues() public view {
        assertEq(address(vesting.token()), address(token));
        assertEq(vesting.beneficiary(), BENEFICIARY);
        assertEq(vesting.totalAllocation(), ALLOCATION);
        assertEq(vesting.start(), START);
        assertEq(vesting.cliff(), START + CLIFF);
        assertEq(vesting.duration(), DURATION);
        assertEq(vesting.released(), 0);
    }

    function test_BeforeCliffNothingIsVested() public view {
        assertEq(vesting.vestedAmount(START), 0);
        assertEq(
            vesting.vestedAmount(START + CLIFF - 1),
            0
        );
        assertEq(
            vesting.releasable(START + CLIFF - 1),
            0
        );
    }

    function test_CliffVestsOneThird() public view {
        uint256 expected = ALLOCATION / 3;

        assertEq(
            vesting.vestedAmount(START + CLIFF),
            expected
        );
    }

    function test_MidpointVestsTwoThirds() public view {
        uint256 timestamp = START + (DURATION * 2) / 3;

        assertEq(
            vesting.vestedAmount(timestamp),
            (ALLOCATION * 2) / 3
        );
    }

    function test_EndVestsEntireAllocation() public view {
        assertEq(
            vesting.vestedAmount(START + DURATION),
            ALLOCATION
        );

        assertEq(
            vesting.vestedAmount(START + DURATION + 1 days),
            ALLOCATION
        );
    }

    function test_ReleasableTracksReleasedAmount() public {
        uint256 timestamp = START + CLIFF;

        vm.warp(timestamp);

        uint256 expected = ALLOCATION / 3;

        assertEq(vesting.releasable(timestamp), expected);

        vesting.release();

        assertEq(vesting.released(), expected);
        assertEq(token.balanceOf(BENEFICIARY), expected);
        assertEq(vesting.releasable(timestamp), 0);
    }

    function test_PartialReleaseThenFinalRelease() public {
        uint256 firstTimestamp =
            START + (DURATION * 2) / 3;

        vm.warp(firstTimestamp);

        uint256 firstAmount = (ALLOCATION * 2) / 3;

        vesting.release();

        assertEq(token.balanceOf(BENEFICIARY), firstAmount);
        assertEq(vesting.released(), firstAmount);

        uint256 finalTimestamp = START + DURATION;

        vm.warp(finalTimestamp);

        vesting.release();

        assertEq(token.balanceOf(BENEFICIARY), ALLOCATION);
        assertEq(vesting.released(), ALLOCATION);
        assertEq(vesting.releasable(finalTimestamp), 0);
    }

    function test_RevertWhenNothingIsReleasable() public {
        vm.warp(START + CLIFF - 1);

        vm.expectRevert("VEXQAR: nothing releasable");
        vesting.release();
    }

    function test_RevertWhenReleasingTwiceWithoutNewVesting() public {
        vm.warp(START + CLIFF);

        vesting.release();

        vm.expectRevert("VEXQAR: nothing releasable");
        vesting.release();
    }

    function test_BeneficiaryCanReceiveFullAllocation() public {
        vm.warp(START + DURATION);

        vesting.release();

        assertEq(token.balanceOf(BENEFICIARY), ALLOCATION);
        assertEq(vesting.released(), ALLOCATION);
        assertEq(token.balanceOf(address(vesting)), 0);
    }

    function test_RevertWhenTokenIsZeroAddress() public {
        vm.expectRevert("VEXQAR: zero token");

        new VEXQARLinearVesting(
            IERC20(address(0)),
            BENEFICIARY,
            ALLOCATION,
            START,
            CLIFF,
            DURATION
        );
    }

    function test_RevertWhenBeneficiaryIsZeroAddress() public {
        vm.expectRevert("VEXQAR: zero beneficiary");

        new VEXQARLinearVesting(
            token,
            address(0),
            ALLOCATION,
            START,
            CLIFF,
            DURATION
        );
    }

    function test_RevertWhenAllocationIsZero() public {
        vm.expectRevert("VEXQAR: zero allocation");

        new VEXQARLinearVesting(
            token,
            BENEFICIARY,
            0,
            START,
            CLIFF,
            DURATION
        );
    }

    function test_RevertWhenDurationIsZero() public {
        vm.expectRevert("VEXQAR: zero duration");

        new VEXQARLinearVesting(
            token,
            BENEFICIARY,
            ALLOCATION,
            START,
            CLIFF,
            0
        );
    }

    function test_RevertWhenCliffExceedsDuration() public {
        vm.expectRevert("VEXQAR: invalid cliff");

        new VEXQARLinearVesting(
            token,
            BENEFICIARY,
            ALLOCATION,
            START,
            DURATION + 1,
            DURATION
        );
    }
}
