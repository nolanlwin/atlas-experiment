# NC106A Modernization Plan (COBOL ➜ Python)

## 1. Objectives & Constraints
- **Goal:** Translate NC106A’s Format 1 `SUBTRACT` validation suite into Python while keeping functional parity with all arithmetic, rounding, size-error, multiple-result, and explicit scope-terminator scenarios.
- **Constraints:**
  - Preserve CCVS harness semantics: headings, pagination, pass/fail/delete/inspect counters, ANSI references, and `report.log` formatting.
  - Keep original data values, operand permutations (including 42-operand limit tests), and dependency relationships between paired tests (e.g., size-error follow-ups).
  - Python implementation must coexist with COBOL version for regression comparison; no behavioral changes unless documented.

## 2. Program Overview
- Exercises every variant of Format 1 `SUBTRACT`: single/multiple operands, `ROUNDED`, `ON SIZE ERROR`, `NOT ON SIZE ERROR`, multiple result fields, mixed DISPLAY/COMP/COMP-3 usages, and explicit scope terminators.
- Uses CCVS infrastructure for reporting plus large WORKING-STORAGE with numeric, signed, packed-decimal, and grouped data.
- Contains stress tests:
  - 42-operand limit checks (F1-25 ↔ F1-26).
  - Multiple targets receiving same subtraction (F1-27 … F1-33).
  - Size-error interplay with explicit `END-SUBTRACT` (F1-34 … F1-39).

## 3. Target Python Architecture
| COBOL Concept                              | Python Representation |
|-------------------------------------------|------------------------|
| Sections/paragraphs                        | Modules + functions grouped by intent (`harness`, `tests.subtract`, `tests.size_error` etc.). |
| WORKING-STORAGE items                      | `dataclasses` or typed containers storing `Decimal`, `int`, or `str` per picture requirements. |
| CCVS harness                               | `TestHarness` class with counters, ANSI refs, remark handling, and output writer. |
| PRINT-FILE / WRITE-LINE                    | `Reporter` abstraction writing to `report.log` with pagination logic (42 lines/page). |
| Size error / rounding                      | Arithmetic helper utilities raising `SizeError` when PIC limits exceeded; use `decimal.Decimal` with configured context. |
| Multiple result fields                     | Helper to apply operations to target lists, preserving rounding rules individually. |
| Explicit scope terminator tests            | Structured Python `with`/context managers or explicit functions ensuring separation of ON/NOT ON blocks. |

### Proposed Package Layout
```
nc106a_py/
    __main__.py          # CLI entry point
    harness.py           # CCVS emulation (counters, PASS/FAIL, writer)
    reporter.py          # File IO + pagination
    models.py            # Dataclasses for numeric fields, figurative constants
    arithmetic.py        # Subtraction helpers (rounding, size checks, multi-target)
    data_init.py         # Original WORKING-STORAGE values
    tests/
        subtract_basic.py
        subtract_size_error.py
        subtract_multi_target.py
        subtract_scope.py
    resources/
        headers.py       # CCVS constant strings
```

## 4. Data Modeling Strategy
1. **Numeric Field Abstractions**
   - Implement `FieldSpec` capturing picture length, scale, sign, usage (DISPLAY/COMP/COMP-3), and editing.
   - Wrap values in `NumericField` storing `Decimal` plus metadata; enforce truncation, padding, and sign rules on assignment.
2. **Arrays & Tables**
   - Represent 42-element structures (`DNAME1…DNAME42`) as lists/dicts, referencing by index for multi-operand tests.
3. **Figurative Constants & Literals**
   - Provide helper to return zeros/spaces/high/low values for requested field specs.
4. **State Container**
   - `WorkingStorage` class instantiating all fields with initial values, supporting `.get(name)` / `.set(name, value)` for readability.

## 5. Control-Flow & Execution Plan
1. **Harness Translation**
   - Port PASS/FAIL/DELETE/INSPT flows, including computed/correct display, ANSI references, and conditional fail info.
   - Maintain dependency counter `REC-CT` for multi-subtests (F1-27+).
2. **Test Definitions**
   - Use data-driven `TestCase` objects with metadata (`name`, `feature`, `ansi_ref`, `description`, `execute` callable).
   - Group tests logically (basic subtracts, size error detection, multiple result fields, explicit scope terminators).
3. **Arithmetic Implementation**
   - `subtract_from(target, operands, rounded=False, on_size_error=None, not_on_size_error=None)`:
     - Compute cumulative subtraction using `Decimal`.
     - Enforce field limits; call appropriate callbacks.
     - Support `ROUNDED` per target basis (apply bankers or COBOL rounding rules -> typically `ROUND_HALF_EVEN` unless spec says `ROUND_HALF_UP`).
     - Accept multiple result targets so each receives operation with its own rounding/size handling.
4. **Size Error Handling**
   - Raise `SizeError` when value exceeds target PIC range. Harness catches and triggers `on_size_error` block; otherwise `not_on_size_error`.
   - Ensure “not affected by size error” tests check field values remain unchanged.
5. **Scope Terminator Tests**
   - Emulate `END-SUBTRACT` semantics via context-managed operations to ensure statements after ON/NOT ON execute correctly.
6. **Limit Tests**
   - Generate operand lists programmatically (range 1–42) to avoid manual duplication while ensuring ordering matches COBOL (DNAME1 first etc.).
7. **Reporting**
   - Mirror headings/hyphen lines; output to `report.log`.
   - For multi-record groups (F1-27+), ensure `REC-CT` increments and `PARDOT-X/DOTVALUE` formatting replicates original numbering.

## 6. Testing Strategy
- **Unit Tests**
  - Arithmetic helper (basic subtract, rounding, overflow detection).
  - Size error dispatch (ensuring targets unchanged when size error occurs).
  - Multiple target runner (ensuring each target processed even when others fail/succeed).
  - Scope terminator emulator (ensuring only intended blocks execute).
- **Golden-File Regression**
  - Execute Python program, produce `report.log`, and diff against COBOL baseline.
- **Static Analysis**
  - Run `pytest`, `ruff` (style), and `mypy` (optional) via Makefile or tox.
- **Property/Boundary Tests**
  - Check 42-operand operations sum to zero.
  - Validate rounding of trailing digits (e.g., `.04`, `.3`, `.001` combos).

## 7. Incremental Roadmap
1. **Phase 0 – Scaffold**
   - Create package, harness skeleton, reporter with pagination, CLI entry, and fixture data loader.
2. **Phase 1 – Core Arithmetic**
   - Implement field specs, Decimal context, subtraction helper.
   - Port basic tests F1-1 … F1-6 to validate infrastructure.
3. **Phase 2 – Rounding & Size Error**
   - Add `ROUNDED`, `ON SIZE ERROR`, `NOT ON SIZE ERROR` logic.
   - Translate F1-7 … F1-24 suites; add unit tests verifying size error behavior.
4. **Phase 3 – Operand Limit Tests**
   - Implement generator for 42-operand sequences; port F1-25 & F1-26 plus validations.
5. **Phase 4 – Multiple Result Fields**
   - Support operations writing to multiple targets simultaneously (F1-27 … F1-33). Ensure state isolation per target.
6. **Phase 5 – Explicit Scope Terminator**
   - Encode context-managed subtract blocks with ON/NOT ON semantics (F1-34 … F1-39).
7. **Phase 6 – Integration & QA**
   - Ensure all tests executed in COBOL order, finalize reporting, produce golden log, document run instructions.

## 8. Deliverables for Next Agent
- Python package skeleton with harness & reporter implemented.
- `WorkingStorage` data definitions covering key fields (representative subset to start).
- Arithmetic helper with unit tests proving rounding and size-error handling.
- Translated subset of tests (recommend F1-1 through F1-10) demonstrating approach.
- CLI command (`python -m nc106a_py`) and Makefile target to run suite + generate `report.log`.
- Documentation describing how to extend tests, manage operand lists, and compare output to COBOL baseline.

## 9. Risks & Mitigations
| Risk | Mitigation |
|------|------------|
| Decimal precision drift | Configure `decimal` context with ≥34 digits, explicit rounding mode, and helper to enforce PIC length. |
| Multi-target side effects | Ensure each target uses snapshot of initial value; write unit tests covering shared operand lists. |
| Scope terminator logic clashing with Python structure | Use dedicated helper/class to emulate ON/NOT ON branching, plus tests verifying statements outside `END-SUBTRACT` behave correctly. |
| Pagination mismatch | Add regression test counting output lines per page to ensure header repetition matches COBOL. |

Following this plan equips the next agent to build a faithful, maintainable Python translation of NC106A that mirrors the COBOL subtract validation suite.
