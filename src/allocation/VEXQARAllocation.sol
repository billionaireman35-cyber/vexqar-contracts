pragma solidity 0.8.35;

contract VEXQARAllocation {
    uint256 public constant TOTAL_SUPPLY = 121_000_000 * 10 ** 18;

    uint256 public constant DEPLOYMENT_LIQUIDITY = 24_200_000 * 10 ** 18;
    uint256 public constant TREASURY = 24_200_000 * 10 ** 18;
    uint256 public constant ECONOMIC_COMMUNITY = 36_300_000 * 10 ** 18;
    uint256 public constant FOUNDER = 18_150_000 * 10 ** 18;
    uint256 public constant STRATEGIC_FUND = 12_100_000 * 10 ** 18;
    uint256 public constant CONTRIBUTORS = 6_050_000 * 10 ** 18;

    address public immutable deploymentLiquidityWallet;
    address public immutable treasuryWallet;
    address public immutable economicCommunityWallet;
    address public immutable founderWallet;
    address public immutable strategicFundWallet;
    address public immutable contributorsWallet;

    constructor(
        address deploymentLiquidityWallet_,
        address treasuryWallet_,
        address economicCommunityWallet_,
        address founderWallet_,
        address strategicFundWallet_,
        address contributorsWallet_
    ) {
        require(deploymentLiquidityWallet_ != address(0), "VEXQAR: zero wallet");
        require(treasuryWallet_ != address(0), "VEXQAR: zero wallet");
        require(economicCommunityWallet_ != address(0), "VEXQAR: zero wallet");
        require(founderWallet_ != address(0), "VEXQAR: zero wallet");
        require(strategicFundWallet_ != address(0), "VEXQAR: zero wallet");
        require(contributorsWallet_ != address(0), "VEXQAR: zero wallet");

        deploymentLiquidityWallet = deploymentLiquidityWallet_;
        treasuryWallet = treasuryWallet_;
        economicCommunityWallet = economicCommunityWallet_;
        founderWallet = founderWallet_;
        strategicFundWallet = strategicFundWallet_;
        contributorsWallet = contributorsWallet_;

        require(
            DEPLOYMENT_LIQUIDITY
                + TREASURY
                + ECONOMIC_COMMUNITY
                + FOUNDER
                + STRATEGIC_FUND
                + CONTRIBUTORS
                == TOTAL_SUPPLY,
            "VEXQAR: allocation mismatch"
        );
    }

    function totalAllocated() external pure returns (uint256) {
        return
            DEPLOYMENT_LIQUIDITY
                + TREASURY
                + ECONOMIC_COMMUNITY
                + FOUNDER
                + STRATEGIC_FUND
                + CONTRIBUTORS;
    }
}
