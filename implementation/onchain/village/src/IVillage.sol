// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

struct Villager {
    address wallet;
    uint256 cap; // basis points, 10000 = 100%
    bool voteReinvest;
    uint256 joinedAt;
    bool isActive;
}

interface IVillage {
    // Events
    event VillagerAdded(uint256 indexed id, address indexed wallet);
    event VillagerRemoved(uint256 indexed id, address indexed wallet);
    event WalletRecovered(uint256 indexed id, address indexed oldWallet, address indexed newWallet);
    event CapUpdated(uint256 indexed id, uint256 oldCap, uint256 newCap);
    event VoteChanged(uint256 indexed id, bool voteReinvest);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    // Owner functions
    function addVillager(address wallet, uint256 cap) external;
    function removeVillager(uint256 id) external;
    function recoverWallet(address oldWallet, address newWallet) external;
    function setCap(uint256 id, uint256 cap) external;
    function transferOwnership(address newOwner) external;

    // Villager functions
    function setVoteReinvest(bool _voteReinvest) external;

    // View functions
    function owner() external view returns (address);
    function getVillager(uint256 id) external view returns (Villager memory);
    function getVillagerByAddress(address wallet) external view returns (Villager memory);
    function getIdByAddress(address wallet) external view returns (uint256);
    function isVillager(address wallet) external view returns (bool);
    function villagerCount() external view returns (uint256);
    function activeCount() external view returns (uint256);
    function getAllVillagers() external view returns (Villager[] memory);
}
