## Context for reviewers

This is a v0.1 spec for a novel instrument. It's designed to be directionally complete—enough to launch and iterate—not legally bulletproof. Many details are intentionally deferred to implementation. If something seems underspecified, it's likely because the spec separates timeless intent from current implementation details, and those details will be worked out as the instrument is built.

The token owner has significant, intentional power asymmetry over shareholders. The token owner controls liquidity (and can change the rules anytime), can dilute without pro rata rights, can force buybacks, and can update parameters. This is the design, not a flaw. Shareholders who find this uncomfortable should not buy. The market prices these powers; shareholders accept them by participating.

Amendments require unanimous shareholder approval. This is a high bar by design. The spec expects token owners to use buybacks to resolve misalignment—buying out dissenters rather than forcing changes on them. If unanimous approval seems impractical, that's because the escape valve is buybacks, not easier amendments.

Shareholders are purely passive economic participants. They have no control, no governance rights, no influence over the token owner's decisions. The asymmetry in the Obligations section (detailed duties for token owner, minimal text for shareholders) reflects this. Shareholders get observation rights, voting on distributions, and the ability to transfer (subject to approval). That's it.

The floor means shareholders may receive nothing if cumulative realized value never exceeds it. This is the risk of the instrument, same as a company that never returns capital. The spec doesn't say what happens in this case because nothing happens—there's simply no value within scope to distribute.

Death settlement is intentionally sparse. The spec states the intent (liquidate, distribute, dissolve) without prescribing implementation because those details depend on the broader ecosystem and the specific holdings involved. This will be fleshed out as implementation progresses.

Classification of Transform vs Exit (whether economic exposure continues or materially changes) involves judgment. In practice, token owners are expected to implement this in code with clear rules, making classification automatic and verifiable. The spec leaves room for this without over-constraining the implementation.
