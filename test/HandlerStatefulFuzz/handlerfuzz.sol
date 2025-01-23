// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Savings} from "src/Savings.sol";
import {Token} from "test/mocks/Token.sol";
import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";


contract Handler is Test {
    Savings public savings;
    Token public token;
    address public user;

    uint256 public ghostTotalDeposits;
    mapping(address => uint256) public ghostBalances;

    constructor(Savings _savings, Token _token) {
        savings = _savings;
        token = _token;
        user = makeAddr("user");
        token.mint(user, type(uint256).max);
        vm.prank(user);
        token.approve(address(savings), type(uint256).max);
    }

    function deposit(uint256 amount) public {
        amount = bound(amount, savings.MIN_DEPOSIT_AMOUNT(), savings.MAX_DEPOSIT_AMOUNT());
        vm.prank(user);
        savings.deposit(amount);

        ghostTotalDeposits += amount;
        ghostBalances[user] += amount;
    }

    function withdraw(uint256 amount) public {
        if (ghostBalances[user] == 0) return;
        
        amount = bound(amount, 1, ghostBalances[user] - 1);
        vm.prank(user);
        savings.withdraw(amount, user);

        ghostTotalDeposits -= amount;
        ghostBalances[user] -= amount;
    }
}

contract SavingsInvariantTest is StdInvariant, Test {
    Savings public savings;
    Token public token;
    Handler public handler;

    function setUp() public {
        token = new Token();
        savings = new Savings(address(token));
        handler = new Handler(savings, token);

        targetContract(address(handler));
    }

    function invariant_balancesMatchGhost() public {
        assertEq(savings.balances(handler.user()), handler.ghostBalances(handler.user()));
    }

    function invariant_totalDepositMatchesGhost() public {
        assertEq(savings.totalDeposited(), handler.ghostTotalDeposits());
    }

    function invariant_totalDepositMatchesBalances() public {
        assertEq(savings.totalDeposited(), savings.balances(handler.user()));
    }

    function invariant_contractBalanceCoversDeposits() public {
        assertGe(
            token.balanceOf(address(savings)),
            savings.totalDeposited()
        );
    }