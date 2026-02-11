// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IVillage, Villager} from "./IVillage.sol";

contract Village is IVillage {
    address public owner;
    uint256 private _nextId;
    uint256 private _activeCount;

    mapping(uint256 => Villager) private _villagers;
    mapping(address => uint256) private _addressToId;

    modifier onlyOwner() {
        require(msg.sender == owner, "Village: caller is not the owner");
        _;
    }

    modifier onlyActiveVillager() {
        uint256 id = _addressToId[msg.sender];
        require(id != 0 && _villagers[id].isActive, "Village: caller is not an active villager");
        _;
    }

    constructor() {
        owner = msg.sender;
        _nextId = 1;

        // Add the owner as villager #1 with 100% cap and voteReinvest = true
        uint256 id = _nextId++;
        _villagers[id] = Villager({
            wallet: msg.sender,
            cap: 10000,
            voteReinvest: true,
            joinedAt: block.timestamp,
            isActive: true
        });
        _addressToId[msg.sender] = id;
        _activeCount++;

        emit VillagerAdded(id, msg.sender);
    }

    // -------------------------------------------------------
    // Owner functions
    // -------------------------------------------------------

    function addVillager(address wallet, uint256 cap) external onlyOwner {
        require(wallet != address(0), "Village: zero address");
        require(_addressToId[wallet] == 0, "Village: address already registered");
        require(cap <= 10000, "Village: cap exceeds 100%");

        uint256 id = _nextId++;
        _villagers[id] = Villager({
            wallet: wallet,
            cap: cap,
            voteReinvest: true,
            joinedAt: block.timestamp,
            isActive: true
        });
        _addressToId[wallet] = id;
        _activeCount++;

        emit VillagerAdded(id, wallet);
    }

    function removeVillager(uint256 id) external onlyOwner {
        require(id != 1, "Village: cannot remove owner");

        Villager storage v = _villagers[id];
        require(v.isActive, "Village: villager not active");

        v.isActive = false;
        delete _addressToId[v.wallet];
        _activeCount--;

        emit VillagerRemoved(id, v.wallet);
    }

    function recoverWallet(address oldWallet, address newWallet) external onlyOwner {
        require(newWallet != address(0), "Village: zero address");
        require(_addressToId[newWallet] == 0, "Village: new address already registered");

        uint256 id = _addressToId[oldWallet];
        require(id != 0, "Village: old address not found");
        require(_villagers[id].isActive, "Village: villager not active");

        delete _addressToId[oldWallet];
        _addressToId[newWallet] = id;
        _villagers[id].wallet = newWallet;

        // If the owner recovers their own wallet, update the owner reference
        if (id == 1) {
            owner = newWallet;
        }

        emit WalletRecovered(id, oldWallet, newWallet);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Village: zero address");

        address oldOwner = owner;
        owner = newOwner;

        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function setCap(uint256 id, uint256 cap) external onlyOwner {
        require(cap <= 10000, "Village: cap exceeds 100%");

        Villager storage v = _villagers[id];
        require(v.isActive, "Village: villager not active");

        uint256 oldCap = v.cap;
        v.cap = cap;

        emit CapUpdated(id, oldCap, cap);
    }

    // -------------------------------------------------------
    // Villager functions
    // -------------------------------------------------------

    function setVoteReinvest(bool _voteReinvest) external onlyActiveVillager {
        uint256 id = _addressToId[msg.sender];
        _villagers[id].voteReinvest = _voteReinvest;

        emit VoteChanged(id, _voteReinvest);
    }

    // -------------------------------------------------------
    // View functions
    // -------------------------------------------------------

    function getVillager(uint256 id) external view returns (Villager memory) {
        return _villagers[id];
    }

    function getVillagerByAddress(address wallet) external view returns (Villager memory) {
        uint256 id = _addressToId[wallet];
        require(id != 0, "Village: address not found");
        return _villagers[id];
    }

    function getIdByAddress(address wallet) external view returns (uint256) {
        return _addressToId[wallet];
    }

    function isVillager(address wallet) external view returns (bool) {
        uint256 id = _addressToId[wallet];
        return id != 0 && _villagers[id].isActive;
    }

    function villagerCount() external view returns (uint256) {
        return _nextId - 1;
    }

    function activeCount() external view returns (uint256) {
        return _activeCount;
    }

    function getAllVillagers() external view returns (Villager[] memory) {
        uint256 count = _nextId - 1;
        Villager[] memory all = new Villager[](count);
        for (uint256 i = 1; i <= count; i++) {
            all[i - 1] = _villagers[i];
        }
        return all;
    }
}
