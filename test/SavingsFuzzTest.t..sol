// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Savings} from "../src/Savings.sol";
import {Token} from "test/mocks/Token.sol";

contract SavingsFuzzTest is Test {
    Savings public savings;
    Token public token;
    address public user;

    function setUp() public {
        token = new Token();
        savings = new Savings(address(token));
        user = makeAddr("user");
        
        token.mint(user, type(uint256).max);
        vm.prank(user);
        token.approve(address(savings), type(uint256).max);
    }

    function testFuzz_Deposit(uint256 amount) public {
        vm.assume(amount >= savings.MIN_DEPOSIT_AMOUNT());
        vm.assume(amount <= savings.MAX_DEPOSIT_AMOUNT());

        uint256 oldBalance = savings.balances(user);
        vm.prank(user);
        savings.deposit(amount);
        assertEq(savings.balances(user), oldBalance + amount);
    }

    function testFail_DepositBelowMin(uint256 amount) public {
        vm.assume(amount < savings.MIN_DEPOSIT_AMOUNT());
        vm.prank(user);
        savings.deposit(amount);
    }

    function testFuzz_Withdraw(uint256 depositAmount, uint256 withdrawAmount) public {
        depositAmount = bound(depositAmount, savings.MIN_DEPOSIT_AMOUNT(), savings.MAX_DEPOSIT_AMOUNT());
        
        vm.prank(user);
        savings.deposit(depositAmount);

        withdrawAmount = bound(withdrawAmount, 1, depositAmount - 1);
        uint256 oldBalance = savings.balances(user);

        vm.prank(user);
        savings.withdraw(withdrawAmount, user);
        assertEq(savings.balances(user), oldBalance - withdrawAmount);
    }

    function testFail_WithdrawExactBalance(uint256 amount) public {
        vm.assume(amount >= savings.MIN_DEPOSIT_AMOUNT());
        vm.assume(amount <= savings.MAX_DEPOSIT_AMOUNT());

        vm.prank(user);
        savings.deposit(amount);

        vm.prank(user);
        savings.withdraw(amount, user);
    }
}


