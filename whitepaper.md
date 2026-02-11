# personal token v0.1

A personal token is an instrument for sharing the economic upside you create over your life.

## Specification

1. **Personal Token.** A personal token represents the economic value a person creates over the course of their life through endeavors with economic outcomes characterized by extreme upside potential, power-law distributions, and superlinear growth.

2. **Holding.** A holding is a position in an upside instrument (such as a company) representing these endeavors.

3. **Value.** Realized value is the token owner's cumulative net realized profit from exits of their holdings.

4. **Floor.** A personal token defines a floor that represents a portion of realized value that is excluded from shareholder claims.

5. **Scope.** The scope of a personal token is the token owner's realized value above the floor.

6. **Shares.** A personal token has shares. Each share represents a proportional claim on the realized value within scope.

7. **Control.** Shareholding in a personal token does not grant control or influence over the token owner's actions, decisions, or life. Shareholding is purely economic participation, not ownership or governance.

8. **Transfer.** Personal token shares are not freely tradable. The token owner retains control over who may hold equity in their token. Secondary transfers require the token owner's approval.

9. **Issuance.** The token owner may issue new shares at any time, diluting existing shareholders. There are no pro rata rights: token owners may refuse shareholders from purchasing future shares.

10. **Buybacks.** The token defines a buyback price function. The token owner may repurchase shares from any shareholder at a price per share no lower than the buyback price as determined by this function at the time of the buyback.

11. **Records.** The state and history of a personal token, including all parameters that affect its operation, are observable to shareholders.

12. **Wallet.** All proceeds from exits of holdings within scope flow to the personal token's wallet.

13. **Distribution.** Any realized value within scope may be allocated to the token owner or distributed pro rata to shareholders as dividends, as determined by ongoing shareholder voting.

14. **Royalties.** When a shareholder profits from selling shares, a percentage of their net profit is transferred to the token owner as royalty, paid in shares.

15. **Dissolution.** Upon dissolution, the personal token is permanently terminated, all outstanding shares are extinguished, and no future holdings are associated with it. For holdings at the moment of dissolution, realized value from their exit remains subject to the personal token's capital flow rules.

16. **Death.** At the death of a token owner, holdings within scope are liquidated, resulting realized value within scope is distributed according to the personal token's capital flow rules, and the personal token is dissolved.

17. **Amendment.** Amendments to the personal token may be proposed by the token owner. Shareholders must approve for the amendment to take effect.

## Design

### State

1. **Owner** — the person behind the token.
2. **Token** — this specific personal token instance, identified uniquely.
3. **Outstanding shares** — the current number of shares in existence.
4. **Shareholders** — participants holding shares, the number of shares held by each, and their current distribution vote.
5. **Wallet** — a designated account through which proceeds from exits of holdings within scope are received and observed.
6. **Holdings** — the set of references to upside instruments that are within scope.
7. **Parameters** — values or functions that define the token's execution.
8. **Agreement** — the agreement governing participation in the personal token, which shareholders accept in order to hold shares.
9. **History** — an append-only record of all events that modify any of the above elements over time.

### Representation

A personal token exists across multiple mediums (legal agreements, onchain systems, and communication), each reflecting a single underlying state.

### Holdings

Holdings exist onchain (including across chains). The personal token's state contains references to these holdings.

## Obligations

### Token Owner Duties

The token owner commits to the following obligations:

- Ensuring all proceeds from exits of holdings within scope are routed to the designated wallet.
- Ensuring accurate acquisition cost is recorded when a holding is added.
- Ensuring that the token's state and history remain observable to shareholders, including all code and configuration that governs the token's operation.
- Ensuring that any divergences across representations of the token's state are reconciled to converge on a single canonical state.

Intentional misrepresentation is subject to applicable law. All other actions and decisions by the token owner are discretionary.

### Shareholder Duties

Shareholders commit to the following obligations:

- Holding shares for their own benefit. Acting as nominee, agent, or proxy for any third party—including holding shares on behalf of another person, entering into agreements that transfer economic interest to non-shareholders, or voting per another party's instructions—is prohibited without the token owner's prior written approval.
- Providing accurate identity and wallet information to the token owner.
- Notifying the token owner promptly of changes to contact information or wallet address.

Violation of these obligations constitutes breach of the Agreement.

### Agreement

The Agreement is intended to faithfully represent the specification, design, obligations, mechanics, and intent described in this document, adapted as necessary to applicable law and jurisdiction. The Agreement must clearly define what is treated as holdings within scope and out-of-scope items for that token ([example](#scope-example)).

## Mechanics

All evaluations are performed against the token's state at the moment of the triggering event.

### Parameters

Parameters have access to the token's state (including history) and may reference external oracles.

- `INITIAL_NUMBER_OF_SHARES`.
- `FLOOR()` —  returns amount.
- `ROYALTY_RATE()` — returns a decimal fraction in `[0, 1)`, representing the percentage of net profit taken as royalty.
- `BUYBACK_PRICE()` — returns amount (price per share).
- `IS_TRANSFER_ALLOWED(transfer)` — given a proposed transfer (seller, buyer, number of shares, price per share), returns boolean. Governs which secondary transfers are permitted.

### Issuing

When issuing shares, the token owner specifies:

- number of new shares to issue,
- recipient,
- price per share.

Issuance increases the total outstanding shares and updates the cap table accordingly.

### Transferring

A transfer consists of:
- seller,
- buyer,
- number of shares,
- price per share.

Transfers require `IS_TRANSFER_ALLOWED()` to return true for the proposed transfer. The token owner defines this function and may update it at any time.

**Royalty calculation:**

1. Compute the seller's cumulative net profit before the transfer: cumulative proceeds minus cumulative cost.
2. Compute cumulative net profit after the transfer: (cumulative proceeds + transaction proceeds) minus cumulative cost.
3. New profit is the portion of the transaction that increases cumulative net profit above zero:
   - `new_profit = max(0, cumulative_net_after) - max(0, cumulative_net_before)`
4. Royalty value = `new_profit × ROYALTY_RATE()`
5. Royalty shares = royalty value ÷ price per share

**Execution:**

- Seller transfers the specified number of shares.
- Royalty shares go to the token owner.
- Buyer receives the remaining shares.
- Buyer pays for shares received (number of shares minus royalty shares) at the agreed price per share.
- Seller receives the buyer's payment.
- The seller bears the full royalty cost; the buyer pays the stated price per share for the shares they receive.
- Seller's cumulative proceeds are updated.

**Buybacks:**

The token owner may initiate a forced transfer (buyback). The seller is a shareholder selected by the token owner, and the price per share must be no lower than `BUYBACK_PRICE()`. Buybacks are exempt from royalty. `IS_TRANSFER_ALLOWED()` does not govern buybacks.

### Distribution Voting

Each share carries one vote with two possible states:

- `REINVEST`
- `DISTRIBUTE`

Shareholders may change their vote at any time. Token owner does not vote.

### Proceeds

Proceeds are the consideration received from an exit of a holding within scope, net of direct transaction fees. Proceeds may be received in cash-like assets (for example, stablecoins) or in other onchain assets; in all cases, proceeds must be received by the personal token wallet and recorded in history, and any non-cash proceeds that remain within scope are recorded as a new holding (Add) or as a continuation of the prior holding (Transform), as appropriate. The acquisition cost of a new holding created from non-cash proceeds is the fair market value of those proceeds at the time of receipt.

### Acquisition Cost

Acquisition cost is the amount the token owner paid to acquire a holding, recorded at the time the holding is added to the set of holdings within scope. 

### Realized Value

On an exit, realized value is computed as proceeds received minus the acquisition cost of the exited portion (net of direct exit fees); realized value can be positive (profit) or negative (loss), and negative realized value reduces cumulative realized value within scope. For partial exits, acquisition cost is allocated proportionally to the exited portion. Transform events (conversions, splits, rollovers) carry forward the acquisition cost from the prior holding form to the new form, allocating proportionally where appropriate.

Transactions on the token owner's own shares – issuance, buybacks, secondary sales – do not affect cumulative net realized value. Realized value is derived solely from exits of holdings within scope.

### Distributing

A realization event is when capital is realized from an exit of a holding. Distributing is evaluated per realization event. An exit may produce multiple realization events over time (e.g., vesting tranches), each evaluated independently. The token tracks cumulative net realized value across all realization events (including losses), and the amount subject to shareholder vote is the portion of the current event that causes cumulative net realized value to exceed the floor.

```
1. cumulative_net = cumulative net realized value within scope to date (can be negative), excluding the current exit event.
2. event_value = realized value within scope from the current exit event (about to be received).
3. floor = FLOOR() at the time of the realization event.

- excess_after_event = (cumulative_net + event_value) - floor
- amount_subject_to_vote = max(0, min(event_value, excess_after_event))

If amount_subject_to_vote > 0:

- If a majority of shares are voting REINVEST, allocate amount_subject_to_vote to the token owner.
- If a majority of shares are voting DISTRIBUTE, distribute amount_subject_to_vote pro rata to shareholders (including the token owner).
```

### Holdings Events

(a) Add: the history records when a holding is added to the set of holdings within scope, with a stable identifier, a reference that lets shareholders verify the holding, and the acquisition cost of the holding.

(b) Transform: the history records transformations where a holding changes form (e.g., conversion, split, rollover) by linking the prior form to the new form.

(c) Exit: the history records exits against a holding, including the portion exited (in instrument-appropriate units or as a percentage); remaining portions stay active; total recorded exits never exceeds the holding. Each exit links to the realized value within scope it produced.

Whether a change in holding form is classified as Transform or Exit depends on whether economic exposure to underlying value is continuous or materially changes. For exits, realized value is recognized when proceeds become receivable; vesting, lockups, or multi-step settlements produce multiple realization events linked to a single exit.

### Amending

The token owner may propose amendments to the personal token, including changes to parameters, mechanics, or the underlying agreement itself. Each amendment is proposed with a defined duration during which shareholders may approve or reject it. While an amendment is active, shareholders may change their stance at any time, and the token owner may withdraw the amendment before it expires. An amendment takes effect when all current shareholders approve it before the proposal expires. The approval set is evaluated dynamically against the live cap table while the amendment is active, so transfers and buybacks can change who must approve. Only one amendment may be active at a time; proposing a new amendment requires withdrawing any currently active amendment. Amendments that expire or are withdrawn have no effect, and applied amendments are recorded as part of the token’s permanent history.

## Norms

### Valuation

Valuation reflects expectations of future outcomes. A personal token may be valued far above the token owner’s present holdings because it prices future value creation that does not yet exist: skills, ventures, opportunities that emerge over the course of a life.

### Alignment

I expect token owners will use buybacks to resolve misalignment around distributions and amendments.

### Structural Integrity

I expect token owners will structure their operations so that obligations are automatic and verifiable. For example: purchasing all holdings through the personal token wallet ensures acquisition cost is recorded as part of transaction history; programmatically managing holdings onchain with smart contracts that enforce proceeds routing to the wallet eliminates manual compliance and makes violations structurally difficult. Over time, I expect implementation patterns to emerge that make correct execution the path of least resistance, reducing both accidental errors and fraud surface area, and I expect the market to reward token owners who achieve integrity through sound structural design.

### Liquidity

I expect token owners will define `IS_TRANSFER_ALLOWED()` to express fine-grained, programmatic constraints on liquidity. This function can encode arbitrary logic: whitelists of approved holders, price floors, holding period requirements, volume limits, time windows, or any combination. Rather than a single permanent liquidity policy, the function can be updated over time - expanded, restricted, paused, or opened as circumstances change.

Because the function is observable to shareholders, the market can price liquidity constraints directly: a restrictive `IS_TRANSFER_ALLOWED()` signals illiquidity and prices accordingly; a permissive one signals easier exit.

### Reputation

I expect the market will reward token owners who keep records current, follow through on stated commitments, communicate meaningful changes in advance, and use dilution, buybacks, and liquidity in ways that compound trust.

### Enforcement

Outside of fraud or material misrepresentation, disagreements are resolved by markets rather than courts.

### Privacy

Early on, I expect token owners will be more transparent than required by the specification, making their token state (including holdings) public. Over time, I expect implementation patterns to emerge that give token owners finer control over information access while preserving onchain verifiability for shareholders.

### Reinvest vs. Distribute

I expect shareholders will vote to reinvest realized value when they expect growth, and to distribute realized value when they expect diminishing upside.

### Safeguards

I expect token owners will adopt a lightweight, non-controlling review process for material actions to provide procedural protection against claims of misrepresentation or bad faith.

### Death Settlement

I expect a broader tokenized ecosystem to emerge with standardized interfaces for shares, exits, and liquidation, enabling clean programmatic settlement on token owner death. Until then, death settlement relies on interim mechanisms. Over time, I expect token owners to prefer holdings that support programmatic liquidation, reducing the operational burden on executors and shareholders.

## Implementation Notes

### Scope Example

> All holdings within scope are represented and settled onchain; tokenized representations of offchain assets are within scope only if the token confers an enforceable claim to the underlying and exit proceeds are settleable onchain to the personal token wallet.

Holdings within scope include equity in private and public companies; equity-like instruments that may convert into equity (options, warrants, SAFEs, convertible notes); token-based upside instruments; and other ownership-like interests aligned with the specification, where upside is primarily realized on exit.

Out-of-scope items include wages and wage-like compensation (salary, fees, bonuses); income-like cashflow rights (for example, revenue share); borrowing and leverage; personal consumption; and retirement accounts and similar long-term savings wrappers.

### FLOOR() example

A fixed floor:

```
FLOOR():
  return 10000000 // $10M
```

An AI-evaluated lifestyle anchor:

```
FLOOR():
  prompt = "What is 5x the 75th percentile price of single-family homes between 2500-3500 sqft in San Francisco?"
  return AI_ORACLE(
    model = "claude-opus-4-5-20251101",
    data_source = HOUSING_ORACLE(region = "San Francisco, CA", property_type = "single-family", sqft_range = [2500, 3500]),
    prompt = prompt
  )

```

### BUYBACK_PRICE() example

NAV per share (net asset value):

```
BUYBACK_PRICE():
  nav = wallet_balance + mark_to_market(holdings) - liabilities
  return nav / outstanding_shares
```

with guaranteed annual appreciation:

```
BUYBACK_PRICE(shareholder):
  original_price = shareholder.average_acquisition_price
  years_held = (now - shareholder.first_purchase_date) / 365
  return original_price * (1.05 ^ years_held)
```

### ROYALTY_RATE() example

A flat 10% royalty:

```
ROYALTY_RATE():
  return 0.10
```

A tiered royalty based on holding period:

```
ROYALTY_RATE(seller, holding_period):
  if holding_period < 365 days:
    return 0.15
  else:
    return 0.05
```

### IS_TRANSFER_ALLOWED() example

A simple whitelist:

```
IS_TRANSFER_ALLOWED(transfer):
  return transfer.buyer in APPROVED_HOLDERS
```

Combining multiple constraints:

```
IS_TRANSFER_ALLOWED(transfer):
  return (
    transfer.buyer in APPROVED_HOLDERS
    AND transfer.price_per_share >= BUYBACK_PRICE()
    AND holder_tenure(transfer.seller) >= 90 days
  )
```

To pause all transfers: `return false`.

Compliance requirements (KYC, jurisdiction restrictions, etc.) can be encoded directly into this function

---

Thanks to [Shiv](https://scholar.google.com/citations?user=WNUGEccAAAAJ&hl=en) for feedback on drafts.
