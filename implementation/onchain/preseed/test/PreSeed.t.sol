// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {PreSeed} from "../src/PreSeed.sol";
import {IPreSeed, InitialInvestment, Investment, InvestmentRecord} from "../src/IPreSeed.sol";

// ---------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------

contract MockUSDC {
    string public name = "USD Coin";
    uint8 public decimals = 6;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balanceOf[from] >= amount, "MockUSDC: insufficient balance");
        require(allowance[from][msg.sender] >= amount, "MockUSDC: insufficient allowance");
        balanceOf[from] -= amount;
        allowance[from][msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

contract MockVillage {
    address public owner;
    uint256 private _nextId = 1;

    struct VillagerInfo {
        bool isActive;
        uint256 id;
    }

    mapping(address => VillagerInfo) private _villagers;
    mapping(uint256 => address) private _idToAddress;

    constructor(address _owner) {
        owner = _owner;
    }

    function addVillager(address wallet) external returns (uint256) {
        uint256 id = _nextId++;
        _villagers[wallet] = VillagerInfo({isActive: true, id: id});
        _idToAddress[id] = wallet;
        return id;
    }

    function removeVillager(address wallet) external {
        _villagers[wallet].isActive = false;
    }

    function isVillager(address wallet) external view returns (bool) {
        if (wallet == owner) return true;
        return _villagers[wallet].isActive;
    }

    function getIdByAddress(address wallet) external view returns (uint256) {
        return _villagers[wallet].id;
    }
}

// ---------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------

contract PreSeedTest is Test {
    PreSeed public preseed;
    MockVillage public village;
    MockUSDC public usdc;

    address constant BASE_USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;

    address owner = address(0xA);
    address alice = address(0xB);
    address bob = address(0xC);
    address charlie = address(0xD);
    address notVillager = address(0xE);

    uint256 aliceId;
    uint256 bobId;
    uint256 charlieId;

    uint256 constant MIN = 25_000e6;
    uint256 constant MAX = 100_000e6;
    uint256 constant TOTAL = 500_000e6;
    uint256 constant PRECISION = 1e18;

    function setUp() public {
        village = new MockVillage(owner);

        // Deploy MockUSDC bytecode at the hardcoded Base USDC address
        MockUSDC mockUsdc = new MockUSDC();
        vm.etch(BASE_USDC, address(mockUsdc).code);
        usdc = MockUSDC(BASE_USDC);

        InitialInvestment[] memory none = new InitialInvestment[](0);
        vm.prank(owner);
        preseed = new PreSeed(address(village), none);

        aliceId = village.addVillager(alice);
        bobId = village.addVillager(bob);
        charlieId = village.addVillager(charlie);

        // Mint USDC and approve
        usdc.mint(alice, 200_000e6);
        usdc.mint(bob, 200_000e6);
        usdc.mint(charlie, 200_000e6);

        vm.prank(alice);
        usdc.approve(address(preseed), type(uint256).max);
        vm.prank(bob);
        usdc.approve(address(preseed), type(uint256).max);
        vm.prank(charlie);
        usdc.approve(address(preseed), type(uint256).max);
    }

    // ---------------------------------------------------------------
    // Constructor
    // ---------------------------------------------------------------

    function test_constructor() public view {
        assertEq(address(preseed.village()), address(village));
        assertEq(preseed.recipient(), owner);
        assertTrue(preseed.isActive());
        assertEq(preseed.totalRaised(), 0);
    }

    // ---------------------------------------------------------------
    // Constructor with initial investments
    // ---------------------------------------------------------------

    function _deployWithInitial(InitialInvestment[] memory inits) internal returns (PreSeed) {
        vm.prank(owner);
        return new PreSeed(address(village), inits);
    }

    function test_constructor_with_initial_investment() public {
        uint256 v1 = village.addVillager(address(0xF1));

        InitialInvestment[] memory inits = new InitialInvestment[](1);
        inits[0] = InitialInvestment({villagerId: v1, amount: 50_000e6});

        PreSeed ps = _deployWithInitial(inits);

        assertEq(ps.totalRaised(), 50_000e6);
        assertEq(ps.getTotalInvested(v1), 50_000e6);
        assertEq(ps.investorCount(), 1);
        assertEq(ps.getInvestorIds()[0], v1);

        Investment[] memory inv = ps.getInvestments(v1);
        assertEq(inv.length, 1);
        assertEq(inv[0].amount, 50_000e6);

        InvestmentRecord[] memory all = ps.getAllInvestments();
        assertEq(all.length, 1);
        assertEq(all[0].villagerId, v1);
    }

    function test_constructor_with_multiple_initial_investments() public {
        uint256 v1 = village.addVillager(address(0xF1));
        uint256 v2 = village.addVillager(address(0xF2));

        InitialInvestment[] memory inits = new InitialInvestment[](2);
        inits[0] = InitialInvestment({villagerId: v1, amount: 50_000e6});
        inits[1] = InitialInvestment({villagerId: v2, amount: 75_000e6});

        PreSeed ps = _deployWithInitial(inits);

        assertEq(ps.totalRaised(), 125_000e6);
        assertEq(ps.getTotalInvested(v1), 50_000e6);
        assertEq(ps.getTotalInvested(v2), 75_000e6);
        assertEq(ps.investorCount(), 2);
        assertEq(ps.remaining(), TOTAL - 125_000e6);
    }

    function test_constructor_initial_then_invest_continues() public {
        InitialInvestment[] memory inits = new InitialInvestment[](1);
        inits[0] = InitialInvestment({villagerId: aliceId, amount: 50_000e6});

        vm.prank(owner);
        PreSeed ps = new PreSeed(address(village), inits);

        vm.prank(bob);
        usdc.approve(address(ps), type(uint256).max);
        vm.prank(bob);
        ps.invest(MIN);

        assertEq(ps.totalRaised(), 50_000e6 + MIN);
        assertEq(ps.investorCount(), 2);
    }

    function test_constructor_same_villager_multiple_initial_investments() public {
        uint256 v1 = village.addVillager(address(0xF1));

        InitialInvestment[] memory inits = new InitialInvestment[](2);
        inits[0] = InitialInvestment({villagerId: v1, amount: 25_000e6});
        inits[1] = InitialInvestment({villagerId: v1, amount: 30_000e6});

        PreSeed ps = _deployWithInitial(inits);

        assertEq(ps.totalRaised(), 55_000e6);
        assertEq(ps.getTotalInvested(v1), 55_000e6);
        assertEq(ps.investorCount(), 1); // deduplicated

        Investment[] memory inv = ps.getInvestments(v1);
        assertEq(inv.length, 2);
    }

    // ---------------------------------------------------------------
    // Agreement
    // ---------------------------------------------------------------

    function test_agreement_is_accessible() public view {
        string memory text = preseed.agreement();
        assertTrue(bytes(text).length > 0);
    }

    // ---------------------------------------------------------------
    // Multiple curve
    // ---------------------------------------------------------------

    function test_multiple_at_floor() public view {
        // At floor (10M), multiple should be 1x = 1e18
        assertEq(preseed.multiple(10_000_000), PRECISION);
    }

    function test_multiple_below_floor() public view {
        // Below floor, multiple should still be 1x
        assertEq(preseed.multiple(5_000_000), PRECISION);
        assertEq(preseed.multiple(0), PRECISION);
    }

    function test_multiple_at_cap() public view {
        // At cap (100M), multiple should be 20x = 20e18
        assertEq(preseed.multiple(100_000_000), 20 * PRECISION);
    }

    function test_multiple_above_cap() public view {
        // Above cap, multiple should be capped at 20x
        assertEq(preseed.multiple(200_000_000), 20 * PRECISION);
        assertEq(preseed.multiple(1_000_000_000), 20 * PRECISION);
    }

    function test_multiple_at_known_points() public view {
        // At 50M: p = 40/90 = 4/9, p^2 = 16/81
        // multiple = 1 + 19 * 16/81 ≈ 4.753
        uint256 m50 = preseed.multiple(50_000_000);
        assertTrue(m50 > 4_700_000_000_000_000_000, "50M multiple should be > 4.7x");
        assertTrue(m50 < 4_800_000_000_000_000_000, "50M multiple should be < 4.8x");

        // At 55M: p = 45/90 = 0.5, p^2 = 0.25
        // multiple = 1 + 19 * 0.25 = 5.75
        uint256 m55 = preseed.multiple(55_000_000);
        assertEq(m55, 5_750_000_000_000_000_000);

        // At 100M: exactly 20x
        uint256 m100 = preseed.multiple(100_000_000);
        assertEq(m100, 20 * PRECISION);
    }

    function test_multiple_increases_monotonically() public view {
        uint256 prev = preseed.multiple(10_000_000);
        for (uint256 i = 1; i <= 18; i++) {
            uint256 valuation = 10_000_000 + i * 5_000_000;
            uint256 m = preseed.multiple(valuation);
            assertTrue(m >= prev, "Multiple must increase monotonically");
            prev = m;
        }
    }

    function test_multiple_is_convex() public view {
        // The deltas should be increasing (convex curve)
        uint256 prevDelta = 0;
        uint256 prev = preseed.multiple(10_000_000);

        for (uint256 i = 1; i <= 9; i++) {
            uint256 valuation = 10_000_000 + i * 10_000_000;
            uint256 m = preseed.multiple(valuation);
            uint256 delta = m - prev;
            if (i > 1) {
                assertTrue(delta > prevDelta, "Deltas must increase (convex)");
            }
            prevDelta = delta;
            prev = m;
        }
    }

    function test_multiple_symmetry_at_midpoint() public view {
        // At midpoint (55M), p = 0.5, p^2 = 0.25
        // multiple = 1 + 19 * 0.25 = 5.75x exactly
        assertEq(preseed.multiple(55_000_000), 5_750_000_000_000_000_000);
    }

    // ---------------------------------------------------------------
    // Invest — happy path
    // ---------------------------------------------------------------

    function test_invest_basic() public {
        vm.prank(alice);
        preseed.invest(MIN);

        assertEq(preseed.totalRaised(), MIN);
        assertEq(preseed.getTotalInvested(aliceId), MIN);
        assertEq(preseed.investorCount(), 1);
        assertEq(usdc.balanceOf(owner), MIN);
    }

    function test_invest_multiple_by_same_villager() public {
        vm.prank(alice);
        preseed.invest(50_000e6);

        vm.prank(alice);
        preseed.invest(50_000e6);

        assertEq(preseed.getTotalInvested(aliceId), MAX);
        assertEq(preseed.investorCount(), 1);

        Investment[] memory inv = preseed.getInvestments(aliceId);
        assertEq(inv.length, 2);
    }

    function test_invest_multiple_investors() public {
        vm.prank(alice);
        preseed.invest(MAX);

        vm.prank(bob);
        preseed.invest(MAX);

        assertEq(preseed.totalRaised(), 200_000e6);
        assertEq(preseed.investorCount(), 2);

        uint256[] memory ids = preseed.getInvestorIds();
        assertEq(ids.length, 2);
        assertEq(ids[0], aliceId);
        assertEq(ids[1], bobId);
    }

    function test_invest_emits_event() public {
        vm.expectEmit(true, false, false, true);
        emit IPreSeed.Invested(aliceId, MIN);

        vm.prank(alice);
        preseed.invest(MIN);
    }

    function test_invest_usdc_transferred_to_recipient() public {
        uint256 aliceBefore = usdc.balanceOf(alice);
        uint256 ownerBefore = usdc.balanceOf(owner);

        vm.prank(alice);
        preseed.invest(50_000e6);

        assertEq(usdc.balanceOf(alice), aliceBefore - 50_000e6);
        assertEq(usdc.balanceOf(owner), ownerBefore + 50_000e6);
    }

    // ---------------------------------------------------------------
    // Invest — validation
    // ---------------------------------------------------------------

    function test_invest_reverts_below_minimum() public {
        vm.prank(alice);
        vm.expectRevert("PreSeed: below minimum investment");
        preseed.invest(MIN - 1);
    }

    function test_invest_reverts_not_multiple_of_min() public {
        vm.prank(alice);
        vm.expectRevert("PreSeed: amount must be a multiple of minimum investment");
        preseed.invest(30_000e6);
    }

    function test_invest_reverts_above_max_per_villager() public {
        vm.prank(alice);
        preseed.invest(MAX);

        vm.prank(alice);
        vm.expectRevert("PreSeed: exceeds maximum investment per villager");
        preseed.invest(MIN);
    }

    function test_invest_reverts_if_would_exceed_max_cumulative() public {
        vm.prank(alice);
        preseed.invest(75_000e6);

        vm.prank(alice);
        vm.expectRevert("PreSeed: exceeds maximum investment per villager");
        preseed.invest(50_000e6);
    }

    function test_invest_reverts_exceeds_total() public {
        // Fill the round: 5 investors at 100K = 500K
        address[6] memory investors;
        for (uint256 i = 0; i < 6; i++) {
            investors[i] = address(uint160(0x100 + i));
            village.addVillager(investors[i]);
            usdc.mint(investors[i], MAX);
            vm.prank(investors[i]);
            usdc.approve(address(preseed), type(uint256).max);
        }

        // First 5 invest 100K each = 500K (full round)
        for (uint256 i = 0; i < 5; i++) {
            vm.prank(investors[i]);
            preseed.invest(MAX);
        }

        assertEq(preseed.totalRaised(), TOTAL);
        assertTrue(preseed.isComplete());

        // 6th investor can't invest
        vm.prank(investors[5]);
        vm.expectRevert("PreSeed: exceeds total round size");
        preseed.invest(MIN);
    }

    function test_invest_partial_fill_then_exact_remainder() public {
        // 4 investors at 100K = 400K, then one at 100K to fill exactly
        address[5] memory investors;
        for (uint256 i = 0; i < 5; i++) {
            investors[i] = address(uint160(0x100 + i));
            village.addVillager(investors[i]);
            usdc.mint(investors[i], MAX);
            vm.prank(investors[i]);
            usdc.approve(address(preseed), type(uint256).max);
        }

        for (uint256 i = 0; i < 4; i++) {
            vm.prank(investors[i]);
            preseed.invest(MAX);
        }

        assertEq(preseed.totalRaised(), 400_000e6);
        assertEq(preseed.remaining(), 100_000e6);

        // Last investor fills exactly
        vm.prank(investors[4]);
        preseed.invest(MAX);

        assertEq(preseed.totalRaised(), TOTAL);
        assertTrue(preseed.isComplete());
    }

    function test_invest_reverts_not_villager() public {
        usdc.mint(notVillager, MAX);
        vm.prank(notVillager);
        usdc.approve(address(preseed), type(uint256).max);

        vm.prank(notVillager);
        vm.expectRevert("PreSeed: caller is not an active villager");
        preseed.invest(MIN);
    }

    function test_invest_reverts_removed_villager() public {
        village.removeVillager(alice);

        vm.prank(alice);
        vm.expectRevert("PreSeed: caller is not an active villager");
        preseed.invest(MIN);
    }

    function test_invest_reverts_when_paused() public {
        vm.prank(owner);
        preseed.pause();

        vm.prank(alice);
        vm.expectRevert("PreSeed: round is paused");
        preseed.invest(MIN);
    }

    // ---------------------------------------------------------------
    // Pause / Resume
    // ---------------------------------------------------------------

    function test_pause() public {
        vm.prank(owner);
        preseed.pause();
        assertFalse(preseed.isActive());
    }

    function test_resume() public {
        vm.prank(owner);
        preseed.pause();

        vm.prank(owner);
        preseed.resume();
        assertTrue(preseed.isActive());
    }

    function test_pause_then_invest_then_resume() public {
        vm.prank(owner);
        preseed.pause();

        vm.prank(alice);
        vm.expectRevert("PreSeed: round is paused");
        preseed.invest(MIN);

        vm.prank(owner);
        preseed.resume();

        vm.prank(alice);
        preseed.invest(MIN);
        assertEq(preseed.totalRaised(), MIN);
    }

    function test_pause_reverts_not_owner() public {
        vm.prank(alice);
        vm.expectRevert("PreSeed: caller is not the owner");
        preseed.pause();
    }

    function test_resume_reverts_not_owner() public {
        vm.prank(owner);
        preseed.pause();

        vm.prank(alice);
        vm.expectRevert("PreSeed: caller is not the owner");
        preseed.resume();
    }

    function test_pause_reverts_already_paused() public {
        vm.prank(owner);
        preseed.pause();

        vm.prank(owner);
        vm.expectRevert("PreSeed: already paused");
        preseed.pause();
    }

    function test_resume_reverts_already_active() public {
        vm.prank(owner);
        vm.expectRevert("PreSeed: already active");
        preseed.resume();
    }

    function test_pause_emits_event() public {
        vm.expectEmit(false, false, false, false);
        emit IPreSeed.Paused();

        vm.prank(owner);
        preseed.pause();
    }

    function test_resume_emits_event() public {
        vm.prank(owner);
        preseed.pause();

        vm.expectEmit(false, false, false, false);
        emit IPreSeed.Resumed();

        vm.prank(owner);
        preseed.resume();
    }

    // ---------------------------------------------------------------
    // View helpers
    // ---------------------------------------------------------------

    function test_isComplete() public {
        assertFalse(preseed.isComplete());

        // Fill round
        address[5] memory investors;
        for (uint256 i = 0; i < 5; i++) {
            investors[i] = address(uint160(0x200 + i));
            village.addVillager(investors[i]);
            usdc.mint(investors[i], MAX);
            vm.prank(investors[i]);
            usdc.approve(address(preseed), type(uint256).max);
        }

        for (uint256 i = 0; i < 5; i++) {
            vm.prank(investors[i]);
            preseed.invest(MAX);
        }

        assertTrue(preseed.isComplete());
    }

    function test_remaining() public view {
        assertEq(preseed.remaining(), TOTAL);
    }

    function test_remaining_after_investment() public {
        vm.prank(alice);
        preseed.invest(50_000e6);
        assertEq(preseed.remaining(), TOTAL - 50_000e6);
    }

    // ---------------------------------------------------------------
    // getAllInvestments
    // ---------------------------------------------------------------

    function test_getAllInvestments_empty() public view {
        InvestmentRecord[] memory all = preseed.getAllInvestments();
        assertEq(all.length, 0);
    }

    function test_getAllInvestments_ordered() public {
        vm.prank(alice);
        preseed.invest(50_000e6);

        vm.prank(bob);
        preseed.invest(75_000e6);

        vm.prank(charlie);
        preseed.invest(25_000e6);

        InvestmentRecord[] memory all = preseed.getAllInvestments();
        assertEq(all.length, 3);

        assertEq(all[0].villagerId, aliceId);
        assertEq(all[0].amount, 50_000e6);

        assertEq(all[1].villagerId, bobId);
        assertEq(all[1].amount, 75_000e6);

        assertEq(all[2].villagerId, charlieId);
        assertEq(all[2].amount, 25_000e6);
    }

    function test_getAllInvestments_multiple_from_same_villager() public {
        vm.prank(alice);
        preseed.invest(50_000e6);

        vm.prank(bob);
        preseed.invest(25_000e6);

        vm.prank(alice);
        preseed.invest(50_000e6);

        InvestmentRecord[] memory all = preseed.getAllInvestments();
        assertEq(all.length, 3);

        assertEq(all[0].villagerId, aliceId);
        assertEq(all[0].amount, 50_000e6);

        assertEq(all[1].villagerId, bobId);
        assertEq(all[1].amount, 25_000e6);

        assertEq(all[2].villagerId, aliceId);
        assertEq(all[2].amount, 50_000e6);
    }

    // ---------------------------------------------------------------
    // Constants are accessible
    // ---------------------------------------------------------------

    function test_constants() public view {
        assertEq(preseed.TOTAL_AMOUNT(), TOTAL);
        assertEq(preseed.MIN_INVESTMENT(), MIN);
        assertEq(preseed.MAX_INVESTMENT(), MAX);
        assertEq(preseed.FLOOR_VALUATION(), 10_000_000);
        assertEq(preseed.CAP_VALUATION(), 100_000_000);
        assertEq(preseed.VALUATION_RANGE(), 90_000_000);
        assertEq(preseed.MAX_MULTIPLE(), 20);
        assertEq(preseed.EXPONENT(), 2);
    }

    // ---------------------------------------------------------------
    // Scenario: full round walkthrough
    // ---------------------------------------------------------------

    function test_full_round_scenario() public {
        // Alice invests 100K
        vm.prank(alice);
        preseed.invest(MAX);

        // Bob invests 100K
        vm.prank(bob);
        preseed.invest(MAX);

        // Charlie invests 50K
        vm.prank(charlie);
        preseed.invest(50_000e6);

        assertEq(preseed.totalRaised(), 250_000e6);
        assertEq(preseed.investorCount(), 3);

        // All USDC went to the owner
        assertEq(usdc.balanceOf(owner), 250_000e6);

        // All investors get the same terms — no curve position differentiation
        // The multiple is the same for everyone regardless of when they invested
        uint256 m = preseed.multiple(50_000_000); // at 50M seed
        assertTrue(m > 4_700_000_000_000_000_000); // ~4.75x

        // Remaining
        assertEq(preseed.remaining(), 250_000e6);
        assertFalse(preseed.isComplete());
    }
}
