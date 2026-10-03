pragma solidity 0.8.35;

import {Script} from "forge-std/Script.sol";
import {VEXQAR} from "../src/core/VEXQAR.sol";
import {VEXQARAllocation} from "../src/allocation/VEXQARAllocation.sol";
import {VEXQAREconomicCommunityRelease} from "../src/economic/VEXQAREconomicCommunityRelease.sol";
import {VEXQARLinearVesting} from "../src/vesting/VEXQARLinearVesting.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract DeployVEXQAR is Script {
    uint256 internal constant TOTAL_SUPPLY = 121_000_000 * 10 ** 18;

    uint256 internal constant DEPLOYMENT_LIQUIDITY = 24_200_000 * 10 ** 18;
    uint256 internal constant TREASURY = 24_200_000 * 10 ** 18;
    uint256 internal constant ECONOMIC_COMMUNITY = 36_300_000 * 10 ** 18;
    uint256 internal constant FOUNDER = 18_150_000 * 10 ** 18;
    uint256 internal constant STRATEGIC_FUND = 12_100_000 * 10 ** 18;
    uint256 internal constant CONTRIBUTORS = 6_050_000 * 10 ** 18;

    uint256 internal constant CLIFF = 365 days;
    uint256 internal constant VESTING_DURATION = 1095 days;
    uint256 internal constant ECONOMIC_DURATION = 1460 days;

    address internal constant DEPLOYMENT_WALLET = 0xae3E3F0C9243ba74B4fbEB38d120C773650aA003;
    address internal constant TREASURY_WALLET = 0x16eEDA72072683cB7b765D2A2218Bd0B152dD827;
    address internal constant ECONOMIC_WALLET = 0x02821b090F7A31d4C809A45262b6c540AdC807C5;
    address internal constant FOUNDER_WALLET = 0xb8365D75d809b7DE1a06d9c3345C7421bbbaFfbb;
    address internal constant STRATEGIC_WALLET = 0x1DCF490f4A26D740073F0AbD370E77c3d2Fac14b;
    address internal constant CONTRIBUTORS_WALLET = 0x43E1e180eD884390651dCAb4E2E6243af299EA1A;

    function run()
        external
        returns (
            VEXQAR token,
            VEXQARAllocation allocation,
            VEXQAREconomicCommunityRelease economicRelease,
            VEXQARLinearVesting treasuryVesting,
            VEXQARLinearVesting founderVesting,
            VEXQARLinearVesting contributorsVesting
        )
    {
        uint256 privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(privateKey);

        vm.startBroadcast(privateKey);

        token = new VEXQAR(deployer);

        allocation = new VEXQARAllocation(
            DEPLOYMENT_WALLET, TREASURY_WALLET, ECONOMIC_WALLET, FOUNDER_WALLET, STRATEGIC_WALLET, CONTRIBUTORS_WALLET
        );

        uint256 start = block.timestamp;

        economicRelease =
            new VEXQAREconomicCommunityRelease(IERC20(address(token)), ECONOMIC_WALLET, start, ECONOMIC_DURATION);

        treasuryVesting =
            new VEXQARLinearVesting(IERC20(address(token)), TREASURY_WALLET, TREASURY, start, CLIFF, VESTING_DURATION);

        founderVesting =
            new VEXQARLinearVesting(IERC20(address(token)), FOUNDER_WALLET, FOUNDER, start, CLIFF, VESTING_DURATION);

        contributorsVesting = new VEXQARLinearVesting(
            IERC20(address(token)), CONTRIBUTORS_WALLET, CONTRIBUTORS, start, CLIFF, VESTING_DURATION
        );

        require(
            DEPLOYMENT_LIQUIDITY + TREASURY + ECONOMIC_COMMUNITY + FOUNDER + STRATEGIC_FUND + CONTRIBUTORS
                == TOTAL_SUPPLY,
            "VEXQAR: deployment allocation mismatch"
        );

        require(token.balanceOf(deployer) == TOTAL_SUPPLY, "VEXQAR: initial supply mismatch");

        require(token.transfer(DEPLOYMENT_WALLET, DEPLOYMENT_LIQUIDITY), "VEXQAR: deployment transfer failed");

        require(token.transfer(address(treasuryVesting), TREASURY), "VEXQAR: treasury transfer failed");

        require(token.transfer(address(economicRelease), ECONOMIC_COMMUNITY), "VEXQAR: economic transfer failed");

        require(token.transfer(address(founderVesting), FOUNDER), "VEXQAR: founder transfer failed");

        require(token.transfer(STRATEGIC_WALLET, STRATEGIC_FUND), "VEXQAR: strategic transfer failed");

        require(token.transfer(address(contributorsVesting), CONTRIBUTORS), "VEXQAR: contributors transfer failed");

        require(token.balanceOf(DEPLOYMENT_WALLET) == DEPLOYMENT_LIQUIDITY, "VEXQAR: deployment balance mismatch");

        require(token.balanceOf(address(treasuryVesting)) == TREASURY, "VEXQAR: treasury balance mismatch");

        require(token.balanceOf(address(economicRelease)) == ECONOMIC_COMMUNITY, "VEXQAR: economic balance mismatch");

        require(token.balanceOf(address(founderVesting)) == FOUNDER, "VEXQAR: founder balance mismatch");

        require(token.balanceOf(STRATEGIC_WALLET) == STRATEGIC_FUND, "VEXQAR: strategic balance mismatch");

        require(token.balanceOf(address(contributorsVesting)) == CONTRIBUTORS, "VEXQAR: contributors balance mismatch");

        require(
            deployer == DEPLOYMENT_WALLET,
            "VEXQAR: deployer must be deployment wallet"
        );

        require(token.totalSupply() == TOTAL_SUPPLY, "VEXQAR: total supply changed");

        vm.stopBroadcast();
    }
}
