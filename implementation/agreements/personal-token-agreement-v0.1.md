# Personal Token Agreement v0.1

This Agreement governs participation in the personal token whose onchain contract references this document. By acquiring shares in this token, you agree to be bound by this Agreement as published onchain at the time of your acquisition.

---

## 1. Definitions

**Share**: A proportional claim on the Token Owner's realized value within scope, as defined by the personal token specification.

**Realized Value**: Cumulative net profit from exits of holdings within scope.

**Scope**: The Token Owner's realized value above the floor. Holdings within scope include equity in companies, equity-like instruments (options, SAFEs, convertible notes), token-based upside instruments, and similar ownership interests where upside is primarily realized on exit.

**Out of Scope**: Wages, salary, fees, bonuses, income-like cashflow rights, personal consumption, retirement accounts, and similar items.

**Floor**: A portion of realized value excluded from shareholder claims, as defined by the FLOOR() parameter.

---

## 2. What Shares Represent

A share represents a proportional economic claim on realized value within scope. Shares entitle holders to:

- Pro rata distributions when realized value within scope exceeds the floor and shareholders vote to distribute
- Voting rights on distribution decisions (reinvest vs. distribute)
- Visibility into the token's state, holdings, and history

---

## 3. What Shares Do Not Represent

Shareholding does not grant:

- Ownership of the Token Owner or their assets
- Control or influence over the Token Owner's decisions or life
- Governance rights beyond distribution voting
- Any claim outside of realized value within scope
- Any guarantee of returns
- Any right to force liquidation or exit

---

## 4. Current State (v0.1)

This token is in early experimental stage:

- **No holdings**: No holdings are currently within scope
- **No distributions**: There is nothing to distribute
- **No transfers**: Shares are not transferable until full contract infrastructure is deployed
- **Manual cap table**: Share records are maintained via a minimal onchain contract, updatable by the Token Owner for legitimate issuances and shareholder-requested changes only

---

## 5. Token Owner Obligations

The Token Owner commits to:

- Ensuring all proceeds from exits of holdings within scope are routed to the designated wallet
- Ensuring accurate acquisition cost is recorded when a holding is added
- Maintaining accurate share records and not modifying balances except for legitimate issuances, approved transfers, or shareholder-requested wallet changes
- Ensuring the token's state and history remain observable to shareholders
- Ensuring any divergences across representations of the token's state are reconciled
- Acting in good faith consistent with the personal token specification

Intentional misrepresentation is subject to applicable law. All other actions and decisions by the Token Owner are discretionary.

---

## 6. Shareholder Obligations

Shareholders commit to:

- Holding shares for their own benefit. Acting as nominee, agent, or proxy for any third party—including holding shares on behalf of another person, entering into agreements that transfer economic interest to non-shareholders, or voting per another party's instructions—is prohibited without the Token Owner's prior written approval.
- Providing accurate identity and wallet information
- Notifying the Token Owner promptly of changes to contact information or wallet address
- Acknowledging the experimental nature of this instrument

Violation of these obligations constitutes breach of this Agreement and may result in forced buyback at the Token Owner's discretion.

---

## 7. Transfers

Shares are not transferable until full contract infrastructure is deployed. Once transfers are enabled:

- All transfers require approval via the IS_TRANSFER_ALLOWED() function
- Profitable transfers are subject to royalty as defined by ROYALTY_RATE()
- The Token Owner may buy back shares at any time at a price no lower than BUYBACK_PRICE()

---

## 8. Distributions

When realized value within scope exceeds the floor:

- Each share carries one vote: REINVEST or DISTRIBUTE
- Majority vote determines allocation
- REINVEST: amount is allocated to the Token Owner
- DISTRIBUTE: amount is distributed pro rata to all shareholders

Token Owner does not vote on distributions.

---

## 9. Amendments

The Token Owner may propose amendments to this Agreement or the token's parameters. Amendments require approval from all current shareholders to take effect. Applied amendments are recorded in the token's onchain history, and the agreement reference is updated accordingly.

Shareholders are bound by the Agreement version in effect at the time of their acquisition, plus any amendments they have approved.

---

## 10. Dissolution

Upon dissolution, the token is permanently terminated and all outstanding shares are extinguished. For holdings existing at dissolution, realized value from their exit remains subject to this Agreement's distribution rules.

---

## 11. Death

At the death of the Token Owner, holdings within scope are liquidated, resulting realized value is distributed according to this Agreement, and the token is dissolved.

---

## 12. Risks

Shareholders acknowledge:

- This is an experiment; the instrument and implementation may change substantially
- The Token Owner may never generate realized value within scope
- Shares may become worthless
- There is no guaranteed liquidity
- Cryptocurrency and smart contracts carry technical risks including loss of funds
- This Agreement and the personal token concept are novel; legal enforceability is untested
- Outside of fraud or material misrepresentation, disagreements are resolved by markets rather than courts

---

## 13. Disputes

Outside of fraud or intentional misrepresentation, parties agree to resolve disputes through direct communication and negotiation rather than litigation.

---

## 14. Acceptance

By acquiring shares in this token, you confirm that you have read and understood this Agreement and the personal token specification, and you agree to be bound by the terms herein.
