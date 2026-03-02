// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IPreSeed, InitialInvestment, Investment, InvestmentRecord} from "./IPreSeed.sol";

interface IVillage {
    function isVillager(address wallet) external view returns (bool);
    function getIdByAddress(address wallet) external view returns (uint256);
    function owner() external view returns (address);
}

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract PreSeed is IPreSeed {

    // -------------------------------------------------------------------
    // Agreement
    // -------------------------------------------------------------------

    string public constant AGREEMENT =
        "PERSONAL TOKEN PRE-SEED AGREEMENT\n"
        "\n"
        "All mechanics are defined by this contract's code. This agreement covers what the code does not.\n"
        "\n"
        "1. This capital converts into newly issued shares at a future seed round. "
        "The conversion multiple is determined by the seed valuation: "
        "multiple = 1 + 19 * ((seedValuation - 10,000,000) / 90,000,000)^2, "
        "capped at 20x when the seed valuation reaches or exceeds 100,000,000 USD. "
        "All pre-seed participants receive the same terms.\n"
        "\n"
        "2. Capital flows to the token owner upon investment. If a seed round never occurs, "
        "invested capital is not returned.\n"
        "\n"
        "3. Participants must be acting for their own benefit, not as nominees or agents "
        "for third parties.\n";

    // -------------------------------------------------------------------
    // Constants
    // -------------------------------------------------------------------

    uint256 public constant TOTAL_AMOUNT = 500_000e6;  // 500,000 USDC (6 decimals)
    uint256 public constant MIN_INVESTMENT = 25_000e6;  // 25,000 USDC per transaction
    uint256 public constant MAX_INVESTMENT = 100_000e6; // 100,000 USDC cumulative per villager

    uint256 public constant FLOOR_VALUATION = 10_000_000;   // 10M USD
    uint256 public constant CAP_VALUATION = 100_000_000;    // 100M USD
    uint256 public constant VALUATION_RANGE = 90_000_000;   // CAP - FLOOR
    uint256 public constant MAX_MULTIPLE = 20;              // 20x at cap
    uint256 public constant EXPONENT = 2;                   // p^2 curve

    uint256 private constant PRECISION = 1e18;
    address public constant BASE_USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;

    // -------------------------------------------------------------------
    // Immutables
    // -------------------------------------------------------------------

    IVillage public immutable village;
    address public immutable recipient;

    // -------------------------------------------------------------------
    // State
    // -------------------------------------------------------------------

    bool public isActive;
    uint256 public totalRaised;

    mapping(uint256 => Investment[]) private _investments;
    mapping(uint256 => uint256) private _totalInvested;
    uint256[] private _investorIds;
    mapping(uint256 => bool) private _isInvestor;
    InvestmentRecord[] private _allInvestments;

    // -------------------------------------------------------------------
    // Modifiers
    // -------------------------------------------------------------------

    modifier onlyOwner() {
        require(msg.sender == village.owner(), "PreSeed: caller is not the owner");
        _;
    }

    // -------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------

    constructor(address _village, InitialInvestment[] memory _initialInvestments) {
        village = IVillage(_village);
        recipient = IVillage(_village).owner();
        isActive = true;

        // Record investments that occurred before contract deployment (no USDC transfer)
        for (uint256 i = 0; i < _initialInvestments.length; i++) {
            uint256 villagerId = _initialInvestments[i].villagerId;
            uint256 amount = _initialInvestments[i].amount;

            totalRaised += amount;
            _totalInvested[villagerId] += amount;
            _investments[villagerId].push(Investment({
                amount: amount,
                timestamp: block.timestamp
            }));

            if (!_isInvestor[villagerId]) {
                _isInvestor[villagerId] = true;
                _investorIds.push(villagerId);
            }

            _allInvestments.push(InvestmentRecord({
                villagerId: villagerId,
                amount: amount,
                timestamp: block.timestamp
            }));

            emit Invested(villagerId, amount);
        }
    }

    // -------------------------------------------------------------------
    // Owner functions
    // -------------------------------------------------------------------

    function pause() external onlyOwner {
        require(isActive, "PreSeed: already paused");
        isActive = false;
        emit Paused();
    }

    function resume() external onlyOwner {
        require(!isActive, "PreSeed: already active");
        isActive = true;
        emit Resumed();
    }

    // -------------------------------------------------------------------
    // Invest
    // -------------------------------------------------------------------

    function invest(uint256 amount) external {
        require(isActive, "PreSeed: round is paused");
        require(amount >= MIN_INVESTMENT, "PreSeed: below minimum investment");
        require(amount % MIN_INVESTMENT == 0, "PreSeed: amount must be a multiple of minimum investment");
        require(totalRaised + amount <= TOTAL_AMOUNT, "PreSeed: exceeds total round size");

        // Caller must be an active villager
        require(village.isVillager(msg.sender), "PreSeed: caller is not an active villager");
        uint256 villagerId = village.getIdByAddress(msg.sender);
        require(villagerId != 0, "PreSeed: villager not found");

        // Enforce per-villager cap
        require(
            _totalInvested[villagerId] + amount <= MAX_INVESTMENT,
            "PreSeed: exceeds maximum investment per villager"
        );

        // Update state
        totalRaised += amount;
        _totalInvested[villagerId] += amount;
        _investments[villagerId].push(Investment({
            amount: amount,
            timestamp: block.timestamp
        }));

        // Track unique investors
        if (!_isInvestor[villagerId]) {
            _isInvestor[villagerId] = true;
            _investorIds.push(villagerId);
        }

        // Record in global ordered list
        _allInvestments.push(InvestmentRecord({
            villagerId: villagerId,
            amount: amount,
            timestamp: block.timestamp
        }));

        // Transfer USDC from investor to recipient
        require(
            IERC20(BASE_USDC).transferFrom(msg.sender, recipient, amount),
            "PreSeed: USDC transfer failed"
        );

        emit Invested(villagerId, amount);
    }

    // -------------------------------------------------------------------
    // View functions
    // -------------------------------------------------------------------

    /// @notice Returns the agreement text stored in this contract.
    function agreement() external pure returns (string memory) {
        return AGREEMENT;
    }

    /// @notice Returns the conversion multiple at a given seed valuation.
    /// @dev multiple = 1 + 19 * ((seedValuation - FLOOR) / RANGE)^2
    ///      Returns value in PRECISION (1e18) scale. 1x = 1e18, 20x = 20e18.
    function multiple(uint256 seedValuation) public pure returns (uint256) {
        if (seedValuation <= FLOOR_VALUATION) return PRECISION;
        if (seedValuation >= CAP_VALUATION) return MAX_MULTIPLE * PRECISION;

        uint256 p = (seedValuation - FLOOR_VALUATION) * PRECISION / VALUATION_RANGE;
        uint256 pSquared = p * p / PRECISION;

        return PRECISION + (MAX_MULTIPLE - 1) * pSquared;
    }

    /// @notice Returns all investments for a given villager.
    function getInvestments(uint256 villagerId) external view returns (Investment[] memory) {
        return _investments[villagerId];
    }

    /// @notice Returns total amount invested by a given villager.
    function getTotalInvested(uint256 villagerId) external view returns (uint256) {
        return _totalInvested[villagerId];
    }

    /// @notice Returns all villager IDs that have invested.
    function getInvestorIds() external view returns (uint256[] memory) {
        return _investorIds;
    }

    /// @notice Returns the number of unique investors.
    function investorCount() external view returns (uint256) {
        return _investorIds.length;
    }

    /// @notice Returns whether the round is fully raised.
    function isComplete() external view returns (bool) {
        return totalRaised >= TOTAL_AMOUNT;
    }

    /// @notice Returns all investments in order, with villager IDs attached.
    function getAllInvestments() external view returns (InvestmentRecord[] memory) {
        return _allInvestments;
    }

    /// @notice Returns USDC remaining before the round is complete.
    function remaining() external view returns (uint256) {
        return TOTAL_AMOUNT - totalRaised;
    }
}
