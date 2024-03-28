// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/forge-std/src/Test.sol";
import {LiquidationProtectionV2} from "src/LiquidationProtectionV2.sol";
import "src/mocks/AaveOracle.m.sol";
import "src/mocks/AavePool.m.sol";
import "src/mocks/ERC20.m.sol";
import "src/mocks/ERC202.m.sol";
import "lib/forge-std/src/Vm.sol";
import "lib/forge-std/src/console.sol";
import "lib/aave-v3-core/contracts/interfaces/IPool.sol";
import "lib/aave-v3-core/contracts/interfaces/IAaveOracle.sol";


contract LiquidationProtectionV2Test is Test {

    LiquidationProtectionV2 public liquidationProtectionV2;
    OracleMock public Oracle;
    PoolMock public Pool;
    Token1 public TOKEN1;
    Token2 public TOKEN2;
    address public Agent;
    address[] public addresses_;
    uint256[] public amts;
    address public actor = 0x1234123412341234123412341234123412341234;
    address strategy;    

    function setUp() public {

        TOKEN1 = new Token1();
        TOKEN2 = new Token2();

        addresses_.push(address(TOKEN1));
        addresses_.push(address(TOKEN2));
        amts.push(1);
        amts.push(2);

        Oracle = new OracleMock(
            addresses_,
            amts
        );
        Pool = new PoolMock(
            address(Oracle)
        );

        Agent = 0x1488148814881488148814881488148814881488;


        vm.deal(actor, 10e18);
        // vm.prank(actor);

        liquidationProtectionV2 = new LiquidationProtectionV2(
            address(TOKEN1),
            address(TOKEN2),
            address(Oracle),
            address(Pool),
            Agent
        );

        strategy = address(liquidationProtectionV2);

        //---
        vm.deal(strategy, 10e18);

        TOKEN1.mint(actor, 10e18);
        TOKEN2.mint(actor, 10e18);

        TOKEN1.mint(strategy, 10e18);
        TOKEN2.mint(strategy, 10e18);

        TOKEN1.mint(address(Pool), 10e18);
        TOKEN2.mint(address(Pool), 10e18);

    }

    function test_Deposit_Strategy() public {

        liquidationProtectionV2.transferOwnership(actor);
        assertEq(liquidationProtectionV2.owner(), actor);

        
        vm.startPrank(actor);
        TOKEN1.approve(strategy, type(uint256).max);
        liquidationProtectionV2.depositCollateral(
            5e18
        );

        (uint256 collateral, uint256 debt, bool exists) = Pool.users(strategy);

        assertEq(exists, true);
        assertEq(collateral, 5e18);

        vm.stopPrank();
    }

    function test_Withdraw_Strategy() public {
        test_Deposit_Strategy();

        vm.startPrank(actor);
        liquidationProtectionV2.withdrawCollateral(
            5e18
        );

        (uint256 collateral, uint256 debt, bool exists) = Pool.users(strategy);
        
        assertEq(exists, true);
        assertEq(collateral, 0);
        assertEq(TOKEN1.balanceOf(actor), 10e18);

        vm.stopPrank();

    }


}