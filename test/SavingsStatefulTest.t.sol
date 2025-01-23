// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Savings} from "src/Savings.sol";
import {Token} from "test/mocks/Token.sol";

contract SavingsStatefulTest is Test {
    Savings public savings;
    Token public token;
    address public user;

    struct Action {
        uint8 actionType;  // 0: deposit, 1: withdraw
        uint256 amount;
    }

    function setUp() public {
        token = new Token();
        savings = new Savings(address(token));
        user = makeAddr("user");
        
        token.mint(user, type(uint256).max);
        vm.prank(user);
        token.approve(address(savings), type(uint256).max);
    }

    function testFuzz_MultipleActions(Action[] memory actions) public {
        uint256 totalBalance = 0;

        for(uint i = 0; i < actions.length; i++) {
            if(actions[i].actionType == 0) {
                // Deposit
                uint256 depositAmount = bound(
                    actions[i].amount,
                    savings.MIN_DEPOSIT_AMOUNT(),
                    savings.MAX_DEPOSIT_AMOUNT()
                );
                vm.prank(user);
                savings.deposit(depositAmount);
                totalBalance += depositAmount;
            } else if(totalBalance > 0) {
                // Only withdraw if there's a balance
                uint256 withdrawAmount = bound(
                    actions[i].amount,
                    1,
                    totalBalance - 1
                );
                vm.prank(user);
                savings.withdraw(withdrawAmount, user);
                totalBalance -= withdrawAmount;
            }

            // Invariant checks
            assertEq(savings.balances(user), totalBalance);
            assertEq(savings.totalDeposited(), totalBalance);
            assertGe(token.balanceOf(address(savings)), totalBalance);
        }
    }
}
