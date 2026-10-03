pragma solidity 0.8.35;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract VEXQARLinearVesting {
    IERC20 public immutable token;
    address public immutable beneficiary;

    uint256 public immutable totalAllocation;
    uint256 public immutable start;
    uint256 public immutable cliff;
    uint256 public immutable duration;

    uint256 public released;

    constructor(
        IERC20 token_,
        address beneficiary_,
        uint256 totalAllocation_,
        uint256 start_,
        uint256 cliffDuration_,
        uint256 vestingDuration_
    ) {
        require(address(token_) != address(0), "VEXQAR: zero token");
        require(beneficiary_ != address(0), "VEXQAR: zero beneficiary");
        require(totalAllocation_ > 0, "VEXQAR: zero allocation");
        require(vestingDuration_ > 0, "VEXQAR: zero duration");
        require(cliffDuration_ <= vestingDuration_, "VEXQAR: invalid cliff");

        token = token_;
        beneficiary = beneficiary_;
        totalAllocation = totalAllocation_;
        start = start_;
        cliff = start_ + cliffDuration_;
        duration = vestingDuration_;
    }

    function vestedAmount(uint256 timestamp)
        public
        view
        returns (uint256)
    {
        if (timestamp < cliff) {
            return 0;
        }

        uint256 end = start + duration;

        if (timestamp >= end) {
            return totalAllocation;
        }

        return
            (totalAllocation * (timestamp - start))
                / duration;
    }

    function releasable(uint256 timestamp)
        public
        view
        returns (uint256)
    {
        uint256 vested = vestedAmount(timestamp);

        if (vested <= released) {
            return 0;
        }

        return vested - released;
    }

    function release() external {
        uint256 amount = releasable(block.timestamp);

        require(amount > 0, "VEXQAR: nothing releasable");

        released += amount;

        require(
            token.transfer(beneficiary, amount),
            "VEXQAR: transfer failed"
        );
    }
}
