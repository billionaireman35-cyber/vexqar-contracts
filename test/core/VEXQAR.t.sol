pragma solidity 0.8.35;

import {Test} from "forge-std/Test.sol";
import {VEXQAR} from "../../src/core/VEXQAR.sol";

contract VEXQARTest is Test {
    VEXQAR internal token;

    address internal initialHolder = address(0x1001);
    address internal recipient = address(0x2002);
    address internal spender = address(0x3003);

    uint256 internal constant EXPECTED_SUPPLY = 121_000_000 * 10 ** 18;

    uint256 internal permitPrivateKey = 0xA11CE;
    address internal permitOwner;

    function setUp() public {
        token = new VEXQAR(initialHolder);
        permitOwner = vm.addr(permitPrivateKey);

        vm.prank(initialHolder);
        token.transfer(permitOwner, 10_000 * 10 ** 18);
    }

    function test_Metadata() public {
        assertEq(token.name(), "VEXQAR");
        assertEq(token.symbol(), "VXR");
        assertEq(token.decimals(), 18);
    }

    function test_MaxSupply() public {
        assertEq(token.MAX_SUPPLY(), EXPECTED_SUPPLY);
        assertEq(token.totalSupply(), EXPECTED_SUPPLY);
    }

    function test_InitialHolderReceivesEntireSupply() public {
        assertEq(
            token.balanceOf(initialHolder),
            EXPECTED_SUPPLY - (10_000 * 10 ** 18)
        );
        assertEq(token.balanceOf(permitOwner), 10_000 * 10 ** 18);
        assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.balanceOf(recipient), 0);
    }

    function test_TransferPreservesTotalSupply() public {
        uint256 amount = 1_000 * 10 ** 18;

        vm.prank(initialHolder);
        bool success = token.transfer(recipient, amount);

        assertTrue(success);
        assertEq(token.balanceOf(recipient), amount);
        assertEq(
            token.balanceOf(initialHolder),
            EXPECTED_SUPPLY - (10_000 * 10 ** 18) - amount
        );
        assertEq(token.totalSupply(), EXPECTED_SUPPLY);
    }

    function test_ApproveAndTransferFrom() public {
        uint256 amount = 500 * 10 ** 18;

        vm.prank(initialHolder);
        token.approve(spender, amount);

        assertEq(token.allowance(initialHolder, spender), amount);

        vm.prank(spender);
        bool success = token.transferFrom(initialHolder, recipient, amount);

        assertTrue(success);
        assertEq(token.balanceOf(recipient), amount);
        assertEq(token.allowance(initialHolder, spender), 0);
        assertEq(token.totalSupply(), EXPECTED_SUPPLY);
    }

    function test_Permit() public {
        uint256 amount = 750 * 10 ** 18;
        uint256 deadline = block.timestamp + 1 days;

        bytes32 domainSeparator = token.DOMAIN_SEPARATOR();

        bytes32 structHash = keccak256(
            abi.encode(
                keccak256(
                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                ),
                permitOwner,
                spender,
                amount,
                token.nonces(permitOwner),
                deadline
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(permitPrivateKey, digest);

        token.permit(
            permitOwner,
            spender,
            amount,
            deadline,
            v,
            r,
            s
        );

        assertEq(token.allowance(permitOwner, spender), amount);
        assertEq(token.nonces(permitOwner), 1);
    }

    function test_RevertWhenInitialHolderIsZeroAddress() public {
        vm.expectRevert(bytes("VEXQAR: zero holder"));
        new VEXQAR(address(0));
    }

    function test_TransferPreservesTotalSupplyAfterMultipleTransfers() public {
        uint256 amountA = 1_000 * 10 ** 18;
        uint256 amountB = 2_000 * 10 ** 18;
        uint256 amountC = 3_000 * 10 ** 18;

        vm.prank(initialHolder);
        token.transfer(recipient, amountA);

        vm.prank(initialHolder);
        token.transfer(spender, amountB);

        vm.prank(permitOwner);
        token.transfer(recipient, amountC);

        assertEq(token.totalSupply(), EXPECTED_SUPPLY);
        assertEq(
            token.balanceOf(initialHolder),
            EXPECTED_SUPPLY
                - (10_000 * 10 ** 18)
                - amountA
                - amountB
        );
        assertEq(token.balanceOf(recipient), amountA + amountC);
        assertEq(token.balanceOf(spender), amountB);
    }

    function testFuzz_TransferPreservesTotalSupply(uint256 amount) public {
        uint256 available = EXPECTED_SUPPLY - (10_000 * 10 ** 18);
        amount = bound(amount, 0, available);

        vm.prank(initialHolder);
        bool success = token.transfer(recipient, amount);

        assertTrue(success);
        assertEq(token.totalSupply(), EXPECTED_SUPPLY);
        assertEq(token.balanceOf(recipient), amount);
        assertEq(token.balanceOf(initialHolder), available - amount);
    }
}
