# Testability & Test Coverage
New code MUST be testable. Tests MUST ship in the same change. No silent skips.

- DI: take collaborators via constructor or `Ref`. No static singletons or global mutable state.
- Pure where possible: prefer pure functions over methods that read ambient state.
- Inject IO: never call `DateTime.now()`, `Random()`, file, network, or platform APIs directly in business logic — wrap in an injectable client.
- No `BuildContext` outside widgets; pass primitives or `Ref` into pure logic.
- Public APIs: add doc comments describing the behavior contract that tests verify.
- Every notifier, repository, client, widget, or route created or modified ships with tests covering the per-artifact matrix in the `testable-code` skill.
- MUST run the test suite before reporting the task complete. Fix red tests; never disable, skip, or comment out a test to make CI pass.
- Turn summary MUST disclose test status: `tests: <N> green, <M> added` or `tests: <N> green, <M> added, <K> updated (<reason>)` or `tests: skipped because <reason from skill §1.2>`. Silent skip is a rule violation.
- Use the `testable-code` skill for the artifact matrix, tooling, run-loop, and disclosure format.
