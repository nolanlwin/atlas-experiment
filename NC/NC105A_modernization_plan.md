# NC105A Modernization Plan (COBOL ➜ Python)

## 1. Objectives & Constraints
- **Goal:** Translate NC105A (MOVE statement format 1 validations) into Python while preserving every test scenario, CCVS accounting, and `report.log` output.
- **Constraints:**
  - Mirror COBOL behaviors: truncation rules, sign handling, JUSTIFIED logic, figurative constants, group moves, edited pictures, COMP/COMP-3 interactions.
  - Maintain CCVS harness structure (pass/fail/delete/inspect counters, headers, pagination).
  - Ensure byte-level equivalence for group/breakdown diagnostics.

## 2. Architecture Mapping
| COBOL Concept                        | Python Equivalent                                             |
|-------------------------------------|---------------------------------------------------------------|
| Sections/paragraphs                  | Module-level functions within packages (`harness`, `tests`).  |
| WORKING-STORAGE literals & groups   | `dataclasses`, typed constants, helper classes for fields.    |
| CCVS harness (printing/reporting)   | `TestHarness` + `Reporter` classes managing counters/logging. |
| MOVE tests (F1-1 … F1-129)          | Data-driven `TestCase` objects executed sequentially.         |
| Diagnostic breakdown paragraphs     | Helper functions producing human-readable diffs.              |
| Numeric/edited picture logic        | Decimal-based helper library enforcing picture semantics.     |

## 3. Data Modeling Strategy
1. **Primitive Fields**
   - Create `NumericField`, `AlphaField`, `AlphaNumericField`, `EditedField` abstractions encapsulating:
     - Picture metadata (length, decimal positions, sign).
     - Packing/truncation/padding rules.
     - Conversion to/from `Decimal`, `int`, `str`.
2. **Group Structures**
   - Represent groups as dataclasses containing nested field instances; provide `.move_from(group)` to copy entire group (byte-level).
3. **Edited Pictures**
   - Build formatter modules replicating COBOL edit behaviors (`CR/DB`, floating sign, currency symbols, suppressing zeros).
   - Predefine patterns for each edited field (e.g., `Z(7),999`, `$0(10)999`).

## 4. Translation Strategy
1. **Project Layout**
   ```
   nc105a_py/
     __main__.py           # CLI entry (python -m nc105a_py)
     harness.py            # CCVS emulation
     reporter.py           # File output + pagination
     fields.py             # Field abstractions + picture parsing
     data_init.py          # Initial constants/work storage equivalents
     tests/
         move_tests.py     # Sequential definitions for F1-1 … F1-129
         edit_tests.py     # EDIT-TEST cases
     diagnostics.py        # Breakdown utilities (A20…A120 equivalents)
   ```
2. **Execution Flow**
   - Harness initializes data via `data_init.py`.
   - Register ordered `TestCase` objects; each has `setup`, `execute`, `assertions`, `metadata`.
   - After each test, harness logs PASS/FAIL and prints computed/correct info if needed.
3. **MOVE Semantics Handling**
   - Implement `move(source, target)` utility interpreting picture compatibility rules (numeric→numeric, numeric→edited, alpha→alphanumeric, group moves).
   - Support figurative constants (SPACE, ZERO, HIGH-VALUE, LOW-VALUE, QUOTE).
   - Provide explicit functions for special cases (JUSTIFIED right, floating sign, synchronous numeric storage).
4. **Diagnostics**
   - For failures needing breakdown (A20–A120), call `diagnostics.write_breakdown(send, receive, length)` to mimic COBOL multi-line output.

## 5. Testing & Validation
- **Unit Tests**
  - Field conversion (padding, truncation, sign handling).
  - Edited picture formatting per pattern, including CR/DB, floating signs, masking.
  - Figurative constant moves and group copy behavior.
- **Integration Tests**
  - Run entire suite, comparing generated `report.log` to COBOL baseline via golden file diff.
  - Ensure PASS/FAIL counts match expected totals.
- **Static Quality**
  - Lint (ruff/flake8) and type-check (mypy) field abstractions and harness.

## 6. Incremental Roadmap
1. **Phase 0 – Scaffold**
   - Create package, harness skeleton, reporter with pagination, CLI entry.
2. **Phase 1 – Data Layer**
   - Implement field abstractions, figurative constants, initial data population mirroring WORKING-STORAGE.
3. **Phase 2 – Core MOVE Tests**
   - Port initial literal-to-field tests (F1-1 … F1-15) ensuring numeric/alphanumeric behaviors.
4. **Phase 3 – Group & Justified Moves**
   - Handle group moves, JUSTIFIED, REDEFINES structures, breakdown diagnostics.
5. **Phase 4 – Edited Moves**
   - Implement edited picture support (NE/AE fields, currency, floating signs) and related tests.
6. **Phase 5 – COMP/Usage Interactions**
   - Cover COMP, COMP-3, synchronized storage (F1-98 … F1-119), ensuring binary layout consistency.
7. **Phase 6 – Figurative/Quote/High/Low Values**
   - Validate figurative constant moves, zero/space handling, high/low value tests.
8. **Phase 7 – Edit Tests (F1-120 … F1-129)**
   - Port remaining edit tests with masked patterns.
9. **Phase 8 – QA & Docs**
   - Finalize regression diff tooling, document run instructions, ensure CI coverage.

## 7. Deliverables for Next Agent
- Python project skeleton with harness, reporter, diagnostics placeholders.
- Implemented field abstraction layer + unit tests for move semantics.
- Ported initial batch of MOVE tests demonstrating approach.
- Script/Makefile target (`make nc105a_py`) running Python suite and generating `report.log`.
- Documentation detailing translation assumptions, how to add tests, and how to compare outputs to COBOL.

Following this plan will enable a faithful, maintainable Python translation of NC105A that preserves the COBOL MOVE validation behavior while leveraging modern Python tooling.
