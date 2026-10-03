pragma solidity 0.8.35;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {VEXQAREconomicCommunityRelease} from "../../src/economic/VEXQAREconomicCommunityRelease.sol";

contract MockEconomicToken {
    mapping(address => uint256) public balanceOf;

    function mint(address account, uint256 amount) external {
        balanceOf[account] += amount;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "MockToken: insufficient");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

contract VEXQAREconomicCommunityReleaseTest is Test {
    uint256 internal constant TOTAL_ALLOCATION = 36_300_000 * 10 ** 18;
    uint256 internal constant IMMEDIATE_ALLOCATION = 1_815_000 * 10 ** 18;
    uint256 internal constant SCHEDULED_ALLOCATION = 34_485_000 * 10 ** 18;
    uint256 internal constant VESTING_DURATION = 1_460 days;

    address internal beneficiary = address(0xBEEF);

    MockEconomicToken internal mockToken;
    VEXQAREconomicCommunityRelease internal release;

    function setUp() public {
        mockToken = new MockEconomicToken();

        release = new VEXQAREconomicCommunityRelease(
            IERC20(address(mockToken)),
            beneficiary,
            block.timestamp,
            VESTING_DURATION
        );

        mockToken.mint(address(release), TOTAL_ALLOCATION);
    }

    function testSpecificationConstants() public pure {
        assertEq(
            IMMEDIATE_ALLOCATION + SCHEDULED_ALLOCATION,
            TOTAL_ALLOCATION
        );

        assertEq(VESTING_DURATION, 1_460 days);
    }

    function testSpecificationHalfwayScheduledVesting() public pure {
        uint256 halfway = SCHEDULED_ALLOCATION / 2;

        assertEq(halfway, 17_242_500 * 10 ** 18);
    }

    function testSpecificationFullScheduledVesting() public pure {
        assertEq(
            SCHEDULED_ALLOCATION,
            34_485_000 * 10 ** 18
        );
    }

    function testInitialState() public view {
        assertEq(address(release.token()), address(mockToken));
        assertEq(release.beneficiary(), beneficiary);
        assertEq(release.start(), block.timestamp);
        assertEq(release.duration(), VESTING_DURATION);
        assertEq(release.released(), 0);
    }

    function testImmediateAllocation() public view {
        assertEq(
            release.IMMEDIATE_ALLOCATION(),
            IMMEDIATE_ALLOCATION
        );
    }

    function testScheduledAllocation() public view {
        assertEq(
            release.SCHEDULED_ALLOCATION(),
            SCHEDULED_ALLOCATION
        );
    }

    function testScheduledVestedBeforeStart() public view {
        assertEq(
            release.scheduledVested(block.timestamp - 1),
            0
        );
    }

    function testScheduledVestedAtStart() public view {
        assertEq(
            release.scheduledVested(block.timestamp),
            0
        );
    }

    function testScheduledVestedHalfway() public {
        vm.warp(block.timestamp + VESTING_DURATION / 2);

        assertEq(
            release.scheduledVested(block.timestamp),
            SCHEDULED_ALLOCATION / 2
        );
    }

    function testScheduledVestedAtEnd() public {
        vm.warp(block.timestamp + VESTING_DURATION);

        assertEq(
            release.scheduledVested(block.timestamp),
            SCHEDULED_ALLOCATION
        );
    }

    function testScheduledVestedAfterEndRemainsCapped() public {
        vm.warp(block.timestamp + VESTING_DURATION + 365 days);

        assertEq(
            release.scheduledVested(block.timestamp),
            SCHEDULED_ALLOCATION
        );
    }

    function testZeroTokenRejected() public {
        vm.expectRevert();
        new VEXQAREconomicCommunityRelease(
            IERC20(address(0)),
            beneficiary,
            block.timestamp,
            VESTING_DURATION
        );
    }

    function testZeroBeneficiaryRejected() public {
        vm.expectRevert();
        new VEXQAREconomicCommunityRelease(
            IERC20(address(mockToken)),
            address(0),
            block.timestamp,
            VESTING_DURATION
        );
    }

    function testZeroDurationRejected() public {
        vm.expectRevert();
        new VEXQAREconomicCommunityRelease(
            IERC20(address(mockToken)),
            beneficiary,
            block.timestamp,
            0
        );
    }

    function testReleaseImmediateAllocation() public {
        release.releaseImmediate();

        assertEq(
            mockToken.balanceOf(beneficiary),
            IMMEDIATE_ALLOCATION
        );

        assertEq(
            release.released(),
            IMMEDIATE_ALLOCATION
        );
    }

    function testImmediateAllocationCannotBeReleasedTwice() public {
        release.releaseImmediate();

        vm.expectRevert();
        release.releaseImmediate();

        assertEq(
            mockToken.balanceOf(beneficiary),
            IMMEDIATE_ALLOCATION
        );
    }

    function testScheduledReleaseAtHalfway() public {
        release.releaseImmediate();

        vm.warp(block.timestamp + VESTING_DURATION / 2);

        release.releaseScheduled();

        assertEq(
            mockToken.balanceOf(beneficiary),
            IMMEDIATE_ALLOCATION + SCHEDULED_ALLOCATION / 2
        );
    }

    function testScheduledReleaseAtEnd() public {
        release.releaseImmediate();

        vm.warp(block.timestamp + VESTING_DURATION);

        release.releaseScheduled();

        assertEq(
            mockToken.balanceOf(beneficiary),
            TOTAL_ALLOCATION
        );

        assertEq(
            release.released(),
            TOTAL_ALLOCATION
        );
    }

    function testScheduledReleaseCannotExceedAllocation() public {
        release.releaseImmediate();

        vm.warp(block.timestamp + VESTING_DURATION);

        release.releaseScheduled();

        vm.expectRevert();
        release.releaseScheduled();

        assertEq(
            mockToken.balanceOf(beneficiary),
            TOTAL_ALLOCATION
        );

        assertEq(
            release.released(),
            TOTAL_ALLOCATION
        );
    }

    function testRepeatedScheduledReleasesCannotExtractExtraTokens() public {
        release.releaseImmediate();

        vm.warp(block.timestamp + VESTING_DURATION / 2);
        release.releaseScheduled();

        uint256 balanceAfterHalf = mockToken.balanceOf(beneficiary);

        vm.warp(block.timestamp + VESTING_DURATION / 2);

        release.releaseScheduled();

        assertEq(
            mockToken.balanceOf(beneficiary),
            TOTAL_ALLOCATION
        );

        assertGt(
            mockToken.balanceOf(beneficiary),
            balanceAfterHalf
        );
    }

    function testTotalReleasedNeverExceedsAllocation() public {
        release.releaseImmediate();

        vm.warp(block.timestamp + VESTING_DURATION);

        release.releaseScheduled();

        assertLe(
            release.released(),
            TOTAL_ALLOCATION
        );

        assertEq(
            release.released(),
            TOTAL_ALLOCATION
        );
    }

    function testScheduledReleaseBeforeImmediateRelease() public {
        vm.warp(block.timestamp + VESTING_DURATION / 2);

        release.releaseScheduled();

        assertEq(
            mockToken.balanceOf(beneficiary),
            SCHEDULED_ALLOCATION / 2
        );

        assertEq(
            release.released(),
            SCHEDULED_ALLOCATION / 2
        );

        release.releaseImmediate();

        assertEq(
            mockToken.balanceOf(beneficiary),
            IMMEDIATE_ALLOCATION + SCHEDULED_ALLOCATION / 2
        );

        assertEq(
            release.released(),
            IMMEDIATE_ALLOCATION + SCHEDULED_ALLOCATION / 2
        );
    }

    function testImmediateReleaseAfterPartialScheduledRelease() public {
        vm.warp(block.timestamp + VESTING_DURATION / 4);

        release.releaseScheduled();

        uint256 scheduledPartial = SCHEDULED_ALLOCATION / 4;

        assertEq(
            mockToken.balanceOf(beneficiary),
            scheduledPartial
        );

        release.releaseImmediate();

        assertEq(
            mockToken.balanceOf(beneficiary),
            scheduledPartial + IMMEDIATE_ALLOCATION
        );

        assertEq(
            release.released(),
            scheduledPartial + IMMEDIATE_ALLOCATION
        );
    }

    function testFullScheduledReleaseBeforeImmediateRelease() public {
        vm.warp(block.timestamp + VESTING_DURATION);

        release.releaseScheduled();

        assertEq(
            mockToken.balanceOf(beneficiary),
            SCHEDULED_ALLOCATION
        );

        assertEq(
            release.released(),
            SCHEDULED_ALLOCATION
        );

        release.releaseImmediate();

        assertEq(
            mockToken.balanceOf(beneficiary),
            TOTAL_ALLOCATION
        );

        assertEq(
            release.released(),
            TOTAL_ALLOCATION
        );
    }

    function testReleasedMatchesBeneficiaryReceivedBalance() public {
        vm.warp(block.timestamp + VESTING_DURATION / 2);

        release.releaseScheduled();
        release.releaseImmediate();

        assertEq(
            release.released(),
            mockToken.balanceOf(beneficiary)
        );

        vm.warp(block.timestamp + VESTING_DURATION / 2);

        release.releaseScheduled();

        assertEq(
            release.released(),
            mockToken.balanceOf(beneficiary)
        );

        assertEq(
            release.released(),
            TOTAL_ALLOCATION
        );
    }
}
