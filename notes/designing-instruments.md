## On designing instruments

*Early, unorganized thoughts on how to design instruments like the personal token.*

### Alive

Things that should remain alive must not be frozen. Bind to reality at the moment of evaluation, not the moment of definition. Allow the system to evolve as understanding deepens.

*Example: `FLOOR()`, `BUYBACK_PRICE()`, and `ROYALTY_RATE()` are functions evaluated at execution time, not values locked at launch. Shareholders may change their distribution vote at any time. Amendment approval is evaluated against the live cap table—transfers during the window change who must approve. Parameters can be rewritten. The system never falls behind reality because it never commits to a stale snapshot.

### Protect right possibilities

Don't foreclose valuable futures before you know what matters.

- **Protect**: The instinct is to collapse, simplify, decide now. Preservation of possibility requires active defense against that instinct.
- **Right**: Not all possibilities, that would be paralysis. The principle demands judgment about which categories of possibilities actually matter.
- **Possibilities**: The instrument is a vessel, a container. It doesn't dictate outcomes; it creates a structure that can hold many outcomes the designer cannot yet predict.

*Example: The spec is medium-agnostic. It describes mechanics without overfitting to any single technical implementation. Parameters are functions, not values, so they can encode logic that doesn't exist yet. Holdings are references to external instruments rather than a fixed enumeration of asset types.

### Structural integrity

Make correct execution the path of least resistance. Compliance should be automatic, not effortful - achieved through structure, not willpower.

*Example: Routing all purchases through the personal token wallet ensures acquisition cost is recorded as part of transaction history. Programmatic holdings management with smart contracts that enforce proceeds routing eliminates manual compliance and makes violations structurally difficult.

### Atomic operations

Operations complete fully or not at all. No partial states that corrupt the record or leave parties exposed.

*Example: On transfer execution, shares move from seller to buyer and consideration moves from buyer to seller atomically. Royalty calculation and transfer happen as part of the same operation, not as a follow-up that could fail independently.

### Auditable

State and history are observable to those with standing to observe. What happened is knowable; what the rules are is knowable.

*Example: History is append-only—events are recorded, never deleted. All parameters that affect the token's operation are observable to shareholders. Holdings include references that let shareholders verify them independently.

### Individual first

The instrument serves the individual's life, not the other way around. The token owner retains meaningful agency over their own trajectory.

*Example: Shareholding does not grant control over the token owner's actions or decisions. The floor excludes a portion of realized value from shareholder claims. The token owner controls who may hold shares (transfer approval) and may buy back any shareholder at any time (buybacks).

### Surrender to market

What cannot be structurally enforced is resolved by markets, not courts. Reputation is priced. Behavior has consequences, but those consequences flow through economic mechanisms.

*Example: Outside of fraud or material misrepresentation, disagreements are resolved by markets rather than courts. A restrictive `IS_TRANSFER_ALLOWED()` signals illiquidity and prices accordingly. The market rewards token owners who keep records current and use dilution and buybacks in ways that compound trust.

### Truthful

When genuinely distinct things exist in reality, the representation should reflect that. Collapsing them into one structure doesn't eliminate complexity — it hides it, forcing every reader to reconstruct the distinction themselves.

*Example: Transform and Exit are both events where a holding changes state. You could model Transform as "Exit with zero realized value plus Add"—technically equivalent. But they represent different realities: Exit is disposition, Transform is continuity. Keeping them separate makes the history self-documenting.

### Unfold

Organize from abstract to concrete. Each layer unfolds from the one above, adding detail without contradicting it. Higher layers remain stable; lower layers adapt more freely.

*Example: The spec moves from Specification (timeless economic intent) to Design (what the token is as an artifact) to Mechanics (how it operates as a state machine) to Implementation Notes (current mappings and examples). You can read the Specification without understanding the Mechanics. The Implementation Notes can change without touching the Specification. Each layer serves a different reader and a different timescale.*