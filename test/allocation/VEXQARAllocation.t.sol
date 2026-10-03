pragma solidity 0.8.35;

import {Test} from "forge-std/Test.sol";
import {VEXQARAllocation} from "../../src/allocation/VEXQARAllocation.sol";

contract VEXQARAllocationTest is Test {
    VEXQARAllocation public allocation;

    address internal constant DEPLOYMENT_WALLET =
        0xae3E3F0C9243ba74B4fbEB38d120C773650aA003;
    address internal constant TREASURY_WALLET =
        0x16eEDA72072683cB7b765D2A2218Bd0B152dD827;
    address internal constant ECONOMIC_WALLET =
        0x02821b090F7A31d4C809A45262b6c540AdC807C5;
    address internal constant FOUNDER_WALLET =
        0xb8365D75d809b7DE1a06d9c3345C7421bbbaFfbb;
    address internal constant STRATEGIC_WALLET =
        0x1DCF490f4A26D740073F0AbD370E77c3d2Fac14b;
    address internal constant CONTRIBUTORS_WALLET =
        0x43E1e180eD884390651dCAb4E2E6243af299EA1A;

    uint256 internal constant EXPECTED_TOTAL =
        121_000_000 * 10 ** 18;

    function setUp() public {
        allocation = new VEXQARAllocation(
            DEPLOYMENT_WALLET,
            TREASURY_WALLET,
            ECONOMIC_WALLET,
            FOUNDER_WALLET,
            STRATEGIC_WALLET,
            CONTRIBUTORS_WALLET
        );
    }

    function test_TotalAllocatedEqualsTotalSupply() public view {
        assertEq(allocation.totalAllocated(), EXPECTED_TOTAL);
        assertEq(allocation.TOTAL_SUPPLY(), EXPECTED_TOTAL);
    }

    function test_ExactAllocations() public view {
        assertEq(
            allocation.DEPLOYMENT_LIQUIDITY(),
            24_200_000 * 10 ** 18
        );
        assertEq(
            allocation.TREASURY(),
            24_200_000 * 10 ** 18
        );
        assertEq(
            allocation.ECONOMIC_COMMUNITY(),
            36_300_000 * 10 ** 18
        );
        assertEq(
            allocation.FOUNDER(),
            18_150_000 * 10 ** 18
        );
        assertEq(
            allocation.STRATEGIC_FUND(),
            12_100_000 * 10 ** 18
        );
        assertEq(
            allocation.CONTRIBUTORS(),
            6_050_000 * 10 ** 18
        );
    }

    function test_WalletsAreCorrect() public view {
        assertEq(
            allocation.deploymentLiquidityWallet(),
            DEPLOYMENT_WALLET
        );
        assertEq(allocation.treasuryWallet(), TREASURY_WALLET);
        assertEq(
            allocation.economicCommunityWallet(),
            ECONOMIC_WALLET
        );
        assertEq(allocation.founderWallet(), FOUNDER_WALLET);
        assertEq(
            allocation.strategicFundWallet(),
            STRATEGIC_WALLET
        );
        assertEq(
            allocation.contributorsWallet(),
            CONTRIBUTORS_WALLET
        );
    }

    function test_RevertWhenDeploymentWalletIsZero() public {
        vm.expectRevert("VEXQAR: zero wallet");

        new VEXQARAllocation(
            address(0),
            TREASURY_WALLET,
            ECONOMIC_WALLET,
            FOUNDER_WALLET,
            STRATEGIC_WALLET,
            CONTRIBUTORS_WALLET
        );
    }

    function test_RevertWhenTreasuryWalletIsZero() public {
        vm.expectRevert("VEXQAR: zero wallet");

        new VEXQARAllocation(
            DEPLOYMENT_WALLET,
            address(0),
            ECONOMIC_WALLET,
            FOUNDER_WALLET,
            STRATEGIC_WALLET,
            CONTRIBUTORS_WALLET
        );
    }

    function test_RevertWhenEconomicWalletIsZero() public {
        vm.expectRevert("VEXQAR: zero wallet");

        new VEXQARAllocation(
            DEPLOYMENT_WALLET,
            TREASURY_WALLET,
            address(0),
            FOUNDER_WALLET,
            STRATEGIC_WALLET,
            CONTRIBUTORS_WALLET
        );
    }

    function test_RevertWhenFounderWalletIsZero() public {
        vm.expectRevert("VEXQAR: zero wallet");

        new VEXQARAllocation(
            DEPLOYMENT_WALLET,
            TREASURY_WALLET,
            ECONOMIC_WALLET,
            address(0),
            STRATEGIC_WALLET,
            CONTRIBUTORS_WALLET
        );
    }

    function test_RevertWhenStrategicWalletIsZero() public {
        vm.expectRevert("VEXQAR: zero wallet");

        new VEXQARAllocation(
            DEPLOYMENT_WALLET,
            TREASURY_WALLET,
            ECONOMIC_WALLET,
            FOUNDER_WALLET,
            address(0),
            CONTRIBUTORS_WALLET
        );
    }

    function test_RevertWhenContributorsWalletIsZero() public {
        vm.expectRevert("VEXQAR: zero wallet");

        new VEXQARAllocation(
            DEPLOYMENT_WALLET,
            TREASURY_WALLET,
            ECONOMIC_WALLET,
            FOUNDER_WALLET,
            STRATEGIC_WALLET,
            address(0)
        );
    }
}
