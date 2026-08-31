# Untested behavior at the close

The two branches for behavior no test actually ran — a UI flow, an external integration, a real ingest — named in `tdd` § Closing the cycle. Take one; never close with the gap unnamed because the suite is green.

- **Eyeball it** — run the project's dev command, exercise the path, and say in the close what you saw and what you did not.
- **Offer `/validate-behavior`** where being wrong is expensive. It is source-blind against a contract fixed before the run, so it catches a product that only *reports* success — which the person who just wrote the code cannot catch by looking. Say what it costs, so they can judge rather than be sold: a contract written first by someone who is not the checker, and a session sharing none of this one's context. It is user-invoked, so this is a suggestion they act on, never a load.
