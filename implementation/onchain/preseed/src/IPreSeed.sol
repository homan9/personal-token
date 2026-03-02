// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

struct InitialInvestment {
    uint256 villagerId;
    uint256 amount;
}

struct Investment {
    uint256 amount;
    uint256 timestamp;
}

struct InvestmentRecord {
    uint256 villagerId;
    uint256 amount;
    uint256 timestamp;
}

interface IPreSeed {
    // Events
    event Invested(uint256 indexed villagerId, uint256 amount);
    event Paused();
    event Resumed();

    // Owner functions
    function pause() external;
    function resume() external;

    // Villager functions
    function invest(uint256 amount) external;

    // View functions
    function recipient() external view returns (address);
    function isActive() external view returns (bool);
    function totalRaised() external view returns (uint256);
    function multiple(uint256 seedValuation) external pure returns (uint256);
    function getInvestments(uint256 villagerId) external view returns (Investment[] memory);
    function getTotalInvested(uint256 villagerId) external view returns (uint256);
    function getInvestorIds() external view returns (uint256[] memory);
    function getAllInvestments() external view returns (InvestmentRecord[] memory);
    function investorCount() external view returns (uint256);
    function isComplete() external view returns (bool);
    function remaining() external view returns (uint256);
    function agreement() external pure returns (string memory);
}
