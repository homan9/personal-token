// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {Village} from "../src/Village.sol";
import {IVillage, Villager} from "../src/IVillage.sol";

contract VillageTest is Test {
    Village public village;

    address public owner = address(this);
    address public alice = address(0xA11CE);
    address public bob = address(0xB0B);
    address public charlie = address(0xC4A511E);

    function setUp() public {
        village = new Village();
    }

    // -------------------------------------------------------
    // Constructor
    // -------------------------------------------------------

    function test_constructor_setsOwner() public view {
        assertEq(village.owner(), owner);
    }

    function test_constructor_addsOwnerAsVillagerOne() public view {
        Villager memory v = village.getVillager(1);
        assertEq(v.wallet, owner);
        assertEq(v.cap, 10000);
        assertTrue(v.voteReinvest);
        assertTrue(v.isActive);
        assertEq(v.joinedAt, block.timestamp);
    }

    function test_constructor_countsAreCorrect() public view {
        assertEq(village.villagerCount(), 1);
        assertEq(village.activeCount(), 1);
    }

    function test_constructor_ownerIsVillager() public view {
        assertTrue(village.isVillager(owner));
    }

    // -------------------------------------------------------
    // addVillager
    // -------------------------------------------------------

    function test_addVillager_basic() public {
        village.addVillager(alice, 500);

        Villager memory v = village.getVillager(2);
        assertEq(v.wallet, alice);
        assertEq(v.cap, 500);
        assertTrue(v.voteReinvest);
        assertTrue(v.isActive);
        assertEq(v.joinedAt, block.timestamp);
    }

    function test_addVillager_incrementsCounters() public {
        village.addVillager(alice, 500);

        assertEq(village.villagerCount(), 2);
        assertEq(village.activeCount(), 2);
    }

    function test_addVillager_sequentialIds() public {
        village.addVillager(alice, 500);
        village.addVillager(bob, 300);
        village.addVillager(charlie, 200);

        assertEq(village.getIdByAddress(alice), 2);
        assertEq(village.getIdByAddress(bob), 3);
        assertEq(village.getIdByAddress(charlie), 4);
        assertEq(village.villagerCount(), 4);
    }

    function test_addVillager_defaultsVoteReinvestToTrue() public {
        village.addVillager(alice, 500);

        Villager memory v = village.getVillager(2);
        assertTrue(v.voteReinvest);
    }

    function test_addVillager_emitsEvent() public {
        vm.expectEmit(true, true, false, false);
        emit IVillage.VillagerAdded(2, alice);

        village.addVillager(alice, 500);
    }

    function test_addVillager_withZeroCap() public {
        village.addVillager(alice, 0);

        Villager memory v = village.getVillager(2);
        assertEq(v.cap, 0);
    }

    function test_addVillager_withMaxCap() public {
        village.addVillager(alice, 10000);

        Villager memory v = village.getVillager(2);
        assertEq(v.cap, 10000);
    }

    function test_addVillager_revertsIfNotOwner() public {
        vm.prank(alice);
        vm.expectRevert("Village: caller is not the owner");
        village.addVillager(bob, 500);
    }

    function test_addVillager_revertsIfZeroAddress() public {
        vm.expectRevert("Village: zero address");
        village.addVillager(address(0), 500);
    }

    function test_addVillager_revertsIfAlreadyRegistered() public {
        village.addVillager(alice, 500);

        vm.expectRevert("Village: address already registered");
        village.addVillager(alice, 300);
    }

    function test_addVillager_revertsIfCapExceeds100Percent() public {
        vm.expectRevert("Village: cap exceeds 100%");
        village.addVillager(alice, 10001);
    }

    // -------------------------------------------------------
    // removeVillager
    // -------------------------------------------------------

    function test_removeVillager_basic() public {
        village.addVillager(alice, 500);
        village.removeVillager(2);

        Villager memory v = village.getVillager(2);
        assertFalse(v.isActive);
    }

    function test_removeVillager_decrementsActiveCount() public {
        village.addVillager(alice, 500);
        assertEq(village.activeCount(), 2);

        village.removeVillager(2);
        assertEq(village.activeCount(), 1);
    }

    function test_removeVillager_preservesTotalCount() public {
        village.addVillager(alice, 500);
        village.removeVillager(2);

        assertEq(village.villagerCount(), 2);
    }

    function test_removeVillager_clearsAddressMapping() public {
        village.addVillager(alice, 500);
        village.removeVillager(2);

        assertFalse(village.isVillager(alice));
        assertEq(village.getIdByAddress(alice), 0);
    }

    function test_removeVillager_preservesHistoricalData() public {
        village.addVillager(alice, 500);
        village.removeVillager(2);

        Villager memory v = village.getVillager(2);
        assertEq(v.wallet, alice);
        assertEq(v.cap, 500);
        assertFalse(v.isActive);
    }

    function test_removeVillager_emitsEvent() public {
        village.addVillager(alice, 500);

        vm.expectEmit(true, true, false, false);
        emit IVillage.VillagerRemoved(2, alice);

        village.removeVillager(2);
    }

    function test_removeVillager_revertsIfNotOwner() public {
        village.addVillager(alice, 500);

        vm.prank(alice);
        vm.expectRevert("Village: caller is not the owner");
        village.removeVillager(2);
    }

    function test_removeVillager_revertsIfOwner() public {
        vm.expectRevert("Village: cannot remove owner");
        village.removeVillager(1);
    }

    function test_removeVillager_revertsIfAlreadyRemoved() public {
        village.addVillager(alice, 500);
        village.removeVillager(2);

        vm.expectRevert("Village: villager not active");
        village.removeVillager(2);
    }

    function test_removeVillager_revertsIfNonexistent() public {
        vm.expectRevert("Village: villager not active");
        village.removeVillager(99);
    }

    // -------------------------------------------------------
    // recoverWallet
    // -------------------------------------------------------

    function test_recoverWallet_basic() public {
        village.addVillager(alice, 500);

        address aliceNew = address(0xA11CE2);
        village.recoverWallet(alice, aliceNew);

        Villager memory v = village.getVillager(2);
        assertEq(v.wallet, aliceNew);
        assertTrue(v.isActive);
        assertEq(v.cap, 500);
    }

    function test_recoverWallet_updatesAddressMapping() public {
        village.addVillager(alice, 500);

        address aliceNew = address(0xA11CE2);
        village.recoverWallet(alice, aliceNew);

        assertEq(village.getIdByAddress(aliceNew), 2);
        assertEq(village.getIdByAddress(alice), 0);
        assertTrue(village.isVillager(aliceNew));
        assertFalse(village.isVillager(alice));
    }

    function test_recoverWallet_preservesData() public {
        village.addVillager(alice, 500);

        // Change some data first
        vm.prank(alice);
        village.setVoteReinvest(false);

        address aliceNew = address(0xA11CE2);
        village.recoverWallet(alice, aliceNew);

        Villager memory v = village.getVillager(2);
        assertEq(v.cap, 500);
        assertFalse(v.voteReinvest);
        assertTrue(v.isActive);
    }

    function test_recoverWallet_ownerCanRecoverOwnWallet() public {
        address ownerNew = address(0x0E1E7);
        village.recoverWallet(owner, ownerNew);

        assertEq(village.owner(), ownerNew);

        Villager memory v = village.getVillager(1);
        assertEq(v.wallet, ownerNew);
    }

    function test_recoverWallet_ownerCanStillOperate_afterOwnRecovery() public {
        address ownerNew = address(0x0E1E7);
        village.recoverWallet(owner, ownerNew);

        // Owner must operate from new address now
        vm.prank(ownerNew);
        village.addVillager(alice, 500);

        assertEq(village.villagerCount(), 2);
    }

    function test_recoverWallet_emitsEvent() public {
        village.addVillager(alice, 500);

        address aliceNew = address(0xA11CE2);

        vm.expectEmit(true, true, true, false);
        emit IVillage.WalletRecovered(2, alice, aliceNew);

        village.recoverWallet(alice, aliceNew);
    }

    function test_recoverWallet_revertsIfNotOwner() public {
        village.addVillager(alice, 500);

        vm.prank(alice);
        vm.expectRevert("Village: caller is not the owner");
        village.recoverWallet(alice, address(0xA11CE2));
    }

    function test_recoverWallet_revertsIfNewAddressIsZero() public {
        village.addVillager(alice, 500);

        vm.expectRevert("Village: zero address");
        village.recoverWallet(alice, address(0));
    }

    function test_recoverWallet_revertsIfNewAddressAlreadyRegistered() public {
        village.addVillager(alice, 500);
        village.addVillager(bob, 300);

        vm.expectRevert("Village: new address already registered");
        village.recoverWallet(alice, bob);
    }

    function test_recoverWallet_revertsIfOldAddressNotFound() public {
        vm.expectRevert("Village: old address not found");
        village.recoverWallet(alice, address(0xA11CE2));
    }

    function test_recoverWallet_revertsIfVillagerNotActive() public {
        village.addVillager(alice, 500);
        village.removeVillager(2);

        vm.expectRevert("Village: old address not found");
        village.recoverWallet(alice, address(0xA11CE2));
    }

    // -------------------------------------------------------
    // setCap
    // -------------------------------------------------------

    function test_setCap_basic() public {
        village.addVillager(alice, 500);
        village.setCap(2, 1000);

        Villager memory v = village.getVillager(2);
        assertEq(v.cap, 1000);
    }

    function test_setCap_canSetToZero() public {
        village.addVillager(alice, 500);
        village.setCap(2, 0);

        Villager memory v = village.getVillager(2);
        assertEq(v.cap, 0);
    }

    function test_setCap_canSetToMax() public {
        village.addVillager(alice, 500);
        village.setCap(2, 10000);

        Villager memory v = village.getVillager(2);
        assertEq(v.cap, 10000);
    }

    function test_setCap_emitsEvent() public {
        village.addVillager(alice, 500);

        vm.expectEmit(true, false, false, true);
        emit IVillage.CapUpdated(2, 500, 1000);

        village.setCap(2, 1000);
    }

    function test_setCap_revertsIfNotOwner() public {
        village.addVillager(alice, 500);

        vm.prank(alice);
        vm.expectRevert("Village: caller is not the owner");
        village.setCap(2, 1000);
    }

    function test_setCap_revertsIfCapExceeds100Percent() public {
        village.addVillager(alice, 500);

        vm.expectRevert("Village: cap exceeds 100%");
        village.setCap(2, 10001);
    }

    function test_setCap_revertsIfVillagerNotActive() public {
        village.addVillager(alice, 500);
        village.removeVillager(2);

        vm.expectRevert("Village: villager not active");
        village.setCap(2, 1000);
    }

    // -------------------------------------------------------
    // transferOwnership
    // -------------------------------------------------------

    function test_transferOwnership_basic() public {
        address newOwner = address(0xBEEF);
        village.transferOwnership(newOwner);

        assertEq(village.owner(), newOwner);
    }

    function test_transferOwnership_newOwnerCanCallOwnerFunctions() public {
        address newOwner = address(0xBEEF);
        village.transferOwnership(newOwner);

        vm.prank(newOwner);
        village.addVillager(alice, 500);

        assertEq(village.villagerCount(), 2);
    }

    function test_transferOwnership_oldOwnerCannotCallOwnerFunctions() public {
        address newOwner = address(0xBEEF);
        village.transferOwnership(newOwner);

        vm.expectRevert("Village: caller is not the owner");
        village.addVillager(alice, 500);
    }

    function test_transferOwnership_emitsEvent() public {
        address newOwner = address(0xBEEF);

        vm.expectEmit(true, true, false, false);
        emit IVillage.OwnershipTransferred(owner, newOwner);

        village.transferOwnership(newOwner);
    }

    function test_transferOwnership_revertsIfNotOwner() public {
        vm.prank(alice);
        vm.expectRevert("Village: caller is not the owner");
        village.transferOwnership(alice);
    }

    function test_transferOwnership_revertsIfZeroAddress() public {
        vm.expectRevert("Village: zero address");
        village.transferOwnership(address(0));
    }

    // -------------------------------------------------------
    // setVoteReinvest
    // -------------------------------------------------------

    function test_setVoteReinvest_canSetToFalse() public {
        village.addVillager(alice, 500);

        vm.prank(alice);
        village.setVoteReinvest(false);

        Villager memory v = village.getVillager(2);
        assertFalse(v.voteReinvest);
    }

    function test_setVoteReinvest_canFlipBackToTrue() public {
        village.addVillager(alice, 500);

        vm.prank(alice);
        village.setVoteReinvest(false);

        vm.prank(alice);
        village.setVoteReinvest(true);

        Villager memory v = village.getVillager(2);
        assertTrue(v.voteReinvest);
    }

    function test_setVoteReinvest_emitsEvent() public {
        village.addVillager(alice, 500);

        vm.prank(alice);
        vm.expectEmit(true, false, false, true);
        emit IVillage.VoteChanged(2, false);

        village.setVoteReinvest(false);
    }

    function test_setVoteReinvest_ownerCanVoteToo() public {
        village.setVoteReinvest(false);

        Villager memory v = village.getVillager(1);
        assertFalse(v.voteReinvest);
    }

    function test_setVoteReinvest_revertsIfNotVillager() public {
        vm.prank(alice);
        vm.expectRevert("Village: caller is not an active villager");
        village.setVoteReinvest(false);
    }

    function test_setVoteReinvest_revertsIfRemovedVillager() public {
        village.addVillager(alice, 500);
        village.removeVillager(2);

        vm.prank(alice);
        vm.expectRevert("Village: caller is not an active villager");
        village.setVoteReinvest(false);
    }

    // -------------------------------------------------------
    // View functions
    // -------------------------------------------------------

    function test_getVillagerByAddress_basic() public {
        village.addVillager(alice, 500);

        Villager memory v = village.getVillagerByAddress(alice);
        assertEq(v.wallet, alice);
        assertEq(v.cap, 500);
    }

    function test_getVillagerByAddress_revertsIfNotFound() public {
        vm.expectRevert("Village: address not found");
        village.getVillagerByAddress(alice);
    }

    function test_isVillager_returnsTrueForActive() public {
        village.addVillager(alice, 500);
        assertTrue(village.isVillager(alice));
    }

    function test_isVillager_returnsFalseForRemoved() public {
        village.addVillager(alice, 500);
        village.removeVillager(2);
        assertFalse(village.isVillager(alice));
    }

    function test_isVillager_returnsFalseForUnknown() public view {
        assertFalse(village.isVillager(alice));
    }

    function test_getIdByAddress_returnsZeroForUnknown() public view {
        assertEq(village.getIdByAddress(alice), 0);
    }

    // -------------------------------------------------------
    // getAllVillagers
    // -------------------------------------------------------

    function test_getAllVillagers_returnsAllInOrder() public {
        village.addVillager(alice, 500);
        village.addVillager(bob, 300);
        village.addVillager(charlie, 200);

        Villager[] memory all = village.getAllVillagers();

        assertEq(all.length, 4);
        assertEq(all[0].wallet, owner);
        assertEq(all[1].wallet, alice);
        assertEq(all[2].wallet, bob);
        assertEq(all[3].wallet, charlie);
    }

    function test_getAllVillagers_includesRemovedVillagers() public {
        village.addVillager(alice, 500);
        village.addVillager(bob, 300);
        village.removeVillager(2);

        Villager[] memory all = village.getAllVillagers();

        assertEq(all.length, 3);
        assertFalse(all[1].isActive);
        assertTrue(all[2].isActive);
    }

    function test_getAllVillagers_singleVillager() public view {
        Villager[] memory all = village.getAllVillagers();

        assertEq(all.length, 1);
        assertEq(all[0].wallet, owner);
    }

    // -------------------------------------------------------
    // Integration scenarios
    // -------------------------------------------------------

    function test_scenario_addRemoveAndReaddDifferentAddress() public {
        village.addVillager(alice, 500);
        village.removeVillager(2);

        // Alice gets a new wallet and is re-added as a new villager
        address aliceNew = address(0xA11CE2);
        village.addVillager(aliceNew, 700);

        assertEq(village.villagerCount(), 3);
        assertEq(village.activeCount(), 2);

        // Old record preserved
        Villager memory old = village.getVillager(2);
        assertFalse(old.isActive);
        assertEq(old.wallet, alice);

        // New record is separate
        Villager memory v = village.getVillager(3);
        assertTrue(v.isActive);
        assertEq(v.wallet, aliceNew);
        assertEq(v.cap, 700);
    }

    function test_scenario_fullLifecycle() public {
        // Add villagers
        village.addVillager(alice, 500);
        village.addVillager(bob, 300);
        village.addVillager(charlie, 200);

        assertEq(village.villagerCount(), 4);
        assertEq(village.activeCount(), 4);

        // Alice changes her vote
        vm.prank(alice);
        village.setVoteReinvest(false);

        // Bob loses his wallet
        address bobNew = address(0xB0B2);
        village.recoverWallet(bob, bobNew);

        // Bob's vote is preserved
        Villager memory bobV = village.getVillagerByAddress(bobNew);
        assertTrue(bobV.voteReinvest);
        assertEq(bobV.cap, 300);

        // Charlie is removed
        village.removeVillager(4);

        assertEq(village.activeCount(), 3);
        assertEq(village.villagerCount(), 4);

        // Update alice's cap
        village.setCap(2, 800);

        Villager memory aliceV = village.getVillager(2);
        assertEq(aliceV.cap, 800);
        assertFalse(aliceV.voteReinvest);
    }

    function test_scenario_removedAddressCanBeReusedByNewVillager() public {
        village.addVillager(alice, 500);
        village.removeVillager(2);

        // The same address can now be registered to a new villager entry
        village.addVillager(alice, 300);

        assertEq(village.getIdByAddress(alice), 3);
        assertEq(village.villagerCount(), 3);

        Villager memory v = village.getVillager(3);
        assertEq(v.cap, 300);
        assertTrue(v.isActive);
    }

    function test_scenario_timestamps() public {
        village.addVillager(alice, 500);

        vm.warp(block.timestamp + 365 days);
        village.addVillager(bob, 300);

        Villager memory aliceV = village.getVillager(2);
        Villager memory bobV = village.getVillager(3);

        assertEq(bobV.joinedAt - aliceV.joinedAt, 365 days);
    }
}
