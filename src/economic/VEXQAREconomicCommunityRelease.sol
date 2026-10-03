pragma solidity 0.8.35;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract VEXQAREconomicCommunityRelease {
    uint256 public constant TOTAL_ALLOCATION = 36_300_000 * 10 ** 18;
    uint256 public constant IMMEDIATE_ALLOCATION = 1_815_000 * 10 ** 18;
    uint256 public constant SCHEDULED_ALLOCATION = 34_485_000 * 10 ** 18;
    uint256 public constant VESTING_DURATION = 1_460 days;

    IERC20 public immutable token;
    address public immutable beneficiary;
    uint256 public immutable start;
    uint256 public immutable duration;

    uint256 public released;
    bool public immediateReleased;

    constructor(
        IERC20 token_,
        address beneficiary_,
        uint256 start_,
        uint256 duration_
    ) {
        require(address(token_) != address(0), "VEXQAR: zero token");
        require(beneficiary_ != address(0), "VEXQAR: zero beneficiary");
        require(duration_ == VESTING_DURATION, "VEXQAR: invalid duration");

        token = token_;
        beneficiary = beneficiary_;
        start = start_;
        duration = duration_;
    }

    function scheduledVested(uint256 timestamp)
        public
        view
        returns (uint256)
    {
        if (timestamp <= start) {
            return 0;
        }

        uint256 elapsed = timestamp - start;

        if (elapsed >= duration) {
            return SCHEDULED_ALLOCATION;
        }

        return (SCHEDULED_ALLOCATION * elapsed) / duration;
    }

    function releasableScheduled(uint256 timestamp)
        public
        view
        returns (uint256)
    {
        uint256 vested = scheduledVested(timestamp);

        uint256 scheduledReleased = released;

        if (scheduledReleased >= IMMEDIATE_ALLOCATION) {
            scheduledReleased -= IMMEDIATE_ALLOCATION;
        } else {
            scheduledReleased = 0;
        }

        if (vested <= scheduledReleased) {
            return 0;
        }

        return vested - scheduledReleased;
    }

    function releaseImmediate() external {
        require(!immediateReleased, "VEXQAR: immediate released");

        immediateReleased = true;
        released += IMMEDIATE_ALLOCATION;

        require(
            token.transfer(beneficiary, IMMEDIATE_ALLOCATION),
            "VEXQAR: transfer failed"
        );
    }

    function releaseScheduled() external {
        uint256 amount = releasableScheduled(block.timestamp);

        require(amount > 0, "VEXQAR: nothing releasable");

        released += amount;

        require(
            token.transfer(beneficiary, amount),
            "VEXQAR: transfer failed"
        );
    }
}
