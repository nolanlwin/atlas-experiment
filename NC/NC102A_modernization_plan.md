# NC102A Modernization Plan (COBOL ➜ Python)

## 1. Objectives & Constraints
- **Goal:** Recreate NC102A’s perform/go/exit validation suite in Python with identical functional behavior, logging, and pass/fail accounting.
- **Constraints:**  
  - Preserve COBOL test semantics, especially complex GO TO DEPENDING chains, PERFORM formats (inline, THRU, TIMES, UNTIL), and EXIT handling.  
  - Produce the same `report.log` layout, counters, and remarks for regression comparison.  
  - Avoid altering existing COBOL assets; Python version should be a side-by-side implementation.

## 2. System Overview & Mapping
| COBOL Construct                           | Python Approach |
|------------------------------------------|-----------------|
| Divisions/Sections/Paragraphs            | Modules + functions/classes grouped by responsibility (e.g., `reporting`, `tests.perform`, `tests.go`). |
| WORKING-STORAGE scalars/tables           | Dataclasses or typed dicts/constants; use `decimal.Decimal` for fixed-point fields. |
| GO/PERFORM flow with DEPENDING, THRU     | Data-driven dispatch tables and helper methods emulating jump tables and loop counts. |
| PRINT-FILE & record formatting           | Logger/writer class buffering strings and writing to `report.log`. |
| Pass/fail counters & remarks             | `TestHarness` object maintaining counters, ANSI reference strings, computed/correct values. |
| EXIT statements                          | Structured Python returns plus context managers to simulate early exits cleanly. |

## 3. Translation Strategy
1. **Project Skeleton**
   - Create package `nc102a_py` with modules: `__main__.py`, `harness.py`, `reporter.py`, `state.py`, `tests/go_tests.py`, `tests/perform_tests.py`, `tests/exit_tests.py`.
   - Add `pyproject.toml` or `requirements.txt` (stdlib only expected).

2. **State & Data Modeling**
   - Define dataclasses for numeric fields (e.g., `FixedDecimalField`) capturing picture constraints, allowing validation and formatting.
   - Initialize all constants (e.g., `GO_TABLE = "87654321"`, numeric literals) in `state.py`.
   - Implement helper to enforce COBOL-like picture limits (size errors, sign, decimal places).

3. **Execution Harness**
   - `TestHarness` orchestrates test registration, execution order mirroring COBOL paragraph flow, and provides APIs: `pass_test`, `fail_test(computed, correct, remark)`, `delete_test`, `inspect_test`.
   - Maintain ANSI reference strings and feature names per test; automatically log via `Reporter`.

4. **Reporter**
   - Mimic `PRINT-DETAIL`, `WRITE-LINE`, and header/footer routines.
   - Provide page/line counting to reproduce pagination (or configurable stub if unnecessary, but include hooks).

5. **GO/EXIT Tests**
   - Encode GO TO / GO DEPENDING scenarios as pure Python call graphs.
   - Use dictionaries mapping dependency indices to handler functions to emulate `GO TO ... DEPENDING`.
   - For EXIT statement tests, ensure Python functions can early-return without side effects, logging pass/fail accordingly.

6. **PERFORM Tests**
   - Model each PERFORM scenario (simple, THRU, TIMES, UNTIL, inline) as separate Python test functions referencing shared helper routines.
   - Recreate nested PERFORM logic with explicit loops and context managers; ensure `EXIT` cases mimic COBOL behavior (e.g., do-nothing functions when not entered).

7. **In-line PERFORM Emulation**
   - For inline PERFORM blocks (`PERFORM ... END-PERFORM`), translate into Python loops with inline body functions to maintain readability.
   - Ensure counter updates and data moves align with COBOL order of operations.

8. **Computed/Correct Handling**
   - Centralize formatting of computed vs correct values (numbers, strings) to match COBOL display (signs, decimals, CR suffix, etc.).
   - Provide helper to capture string expectations (e.g., `PERFORM-HOLD` sequences).

9. **Testing & Validation**
   - Unit tests for:
     - GO DEPENDING dispatcher given table values.
     - PERFORM TIMES/UNTIL loops (boundary conditions, ignored negative counts).
     - Inline PERFORM arithmetic updates.
   - Integration test that executes all Python tests and diffs generated `report.log` against COBOL baseline.
   - Possibly property tests ensuring counters sum correctly (PASS+FAIL+DELETE+INSPECT equals total run).

10. **Tooling & Documentation**
    - README section describing how to run Python version (`python -m nc102a_py`), where output lives, and how to compare logs.
    - Optional `Makefile` target `make nc102a_py` running translation + tests.

## 4. Incremental Roadmap
1. **Phase 0 – Setup:** Create project structure, harness, reporter stub, state initialization.
2. **Phase 1 – Basic Flow:** Implement headers/footers, pass/fail counters, simple GO tests (formats 1 & 2).
3. **Phase 2 – GO DEPENDING:** Encode complex GO table scenarios, ensuring data-driven approach handles indices 0–7.
4. **Phase 3 – PERFORM Option 1 & 2:** Port simple PERFORM and PERFORM TIMES/THRU cases; validate state updates via unit tests.
5. **Phase 4 – Nested & Section PERFORM:** Handle PERFORM THRU sections, nested sequences, inline PERFORM bodies, EXIT paragraphs.
6. **Phase 5 – PERFORM UNTIL & Inline:** Implement UNTIL loops (pre/post condition variations) and inline PERFORM blocks with END-PERFORM.
7. **Phase 6 – Finalization:** Complete remaining tests (A101 sequence builder, PFM-U safety abort), polish reporter, and ensure parity.
8. **Phase 7 – Verification:** Add automated diff test vs golden log, finalize documentation, integrate into CI if available.

## 5. Risk Mitigation
- **Control-Flow Fidelity:** Use explicit test definitions with expected branches to avoid missing edge cases from COBOL GO TOs; include tracing logs while developing.
- **Numeric Precision:** Where COBOL uses packed/decimal, rely on `decimal.Decimal` with configured contexts; implement guards for overflows analogous to picture limits.
- **Loop Semantics:** Confirm PERFORM TIMES ignores negative/zero iterations; include tests matching COBOL behavior (e.g., negative count ignored, positive uses initial value only).
- **Reporter Pagination:** If exact pagination not needed, document the deviation; otherwise simulate 42-line pages as COBOL program does.

## 6. Deliverables for Next Agent
- Python project skeleton with harness/reporter scaffolding.
- Dataclass representations for key fields and constants.
- Implemented GO format tests (F1/F2 groups) demonstrating dispatcher pattern.
- Sample PERFORM tests translated with accompanying unit tests.
- Script/command to run Python suite and generate `report.log`.
- Documentation outlining how to extend tests and verify against COBOL baseline.

Following this plan will give the next agent a clear blueprint to deliver a faithful, maintainable Python translation of NC102A while preserving the COBOL validation semantics.
