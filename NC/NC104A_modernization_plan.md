# NC104A Modernization Plan (COBOL ➜ Python)

## 1. Objectives & Constraints
- **Primary Goal:** Re-implement NC104A’s MOVE format 1 validation program in Python while preserving test semantics, data coverage, and report formatting.
- **Constraints:**  
  - Maintain CCVS harness behavior (pass/fail/delete/inspect counters, headers, pagination, ANSI references).  
  - Preserve the exact sequence of MOVE permutations across numeric, numeric-edited, alphanumeric, and alphabetic fields, including limit tests.  
  - Python translation must be side-by-side with the COBOL baseline for regression comparisons; no behavior changes allowed without documentation.

## 2. High-Level Architecture Mapping
| COBOL Concept                              | Python Equivalent                                                     |
|-------------------------------------------|------------------------------------------------------------------------|
| Divisions/Sections/Paragraphs             | Modules + classes/functions (`main.py`, `harness.py`, `tests/*.py`).   |
| WORKING-STORAGE data items                | `dataclasses`/typed structures (`decimal.Decimal`, `str`, enums).      |
| CCVS reporting (PRINT-FILE)               | `Reporter` class writing to `report.log` with pagination logic.        |
| PASS/FAIL routines                        | `TestHarness` methods `pass_test`, `fail_test`, `delete_test`, etc.    |
| MOVE test paragraphs                      | Data-driven `TestCase` definitions executed sequentially.             |
| ANSI references & remarks                 | Embedded metadata in each `TestCase`, surfaced in failure output.     |

## 3. Proposed Python Module Layout
```
nc104a_py/
├── __main__.py          # CLI entry: parse args, instantiate runner.
├── harness.py           # CCVS emulation: counters, recorder, pagination.
├── reporter.py          # Low-level file writer with headings & formatting.
├── data_models.py       # Dataclasses for numeric/alphanumeric fields & helpers.
├── move_tests.py        # All MOVE Format 1 test definitions (F1-1 … F1-60).
├── limit_tests.py       # Large operand-count limit scenarios (F1-57 … F1-60).
├── resources/headers.py # Constant strings for CCVS headers/footers.
└── tests/               # pytest-based unit tests for helper utilities.
```

## 4. Data Modeling Strategy
1. **Numeric Fields:** Use `decimal.Decimal` with contexts sized per COBOL picture; wrap in helper class (`NumericField`) enforcing scale, zero-padding, truncation, and CR/DB suffix logic.
2. **Edited Fields:** Implement formatter functions to inject currency symbols, commas, CR, check-protect, blank-when-zero behaviors. Store metadata (picture, blank when zero, insertion chars) to drive formatting.
3. **Alphanumeric/Alphabetic:** Represent as plain strings but centralize padding/truncation helpers to ensure consistent behavior for every MOVE case.
4. **Arrays of Fields:** For limit tests (DNAME*, ANDATA*), represent as lists/dicts keyed by identifier for easy iteration.

## 5. Execution & Control-Flow Plan
1. **Harness Initialization**
   - On startup, populate all data items with COBOL initial values.
   - Build ordered list of `TestCase` objects mirroring COBOL paragraph order (init, test, write).
2. **TestCase Structure**
   - Attributes: `name`, `feature`, `ansi_ref`, `setup_fn`, `action_fn`, `assertions`, `expected`, `computed_formatter`, `remark`.
   - `setup_fn` replicates MOVE-INIT paragraphs.
   - `action_fn` performs the MOVE and captures resulting field states.
   - `assertions` verify receiving field contents; on failure, record computed/correct values as COBOL would.
3. **Reporting**
   - After each test, call `reporter.write_detail(test_result)`.
   - Implement fail and bail-out flows identical to COBOL: include computed/correct rows when needed, otherwise emit informational block.
4. **Pagination**
   - Track `record_count`; when >42 lines, emit headers (H-1, H-2A/B, H-3, column names, hyphen line) before resuming, just like COBOL.
5. **Termination**
   - After tests, execute end routine summary: totals, “TEST(S) FAILED/DELETED/REQUIRE INSPECTION”, `END OF TEST` banner, etc.

## 6. Translation Workflow
1. **Phase 0 – Scaffolding**
   - Initialize Python package, configure `pyproject.toml`, add `ruff`/`black`/`pytest`.
   - Implement `Reporter` with placeholder headings to verify pagination logic early.
2. **Phase 1 – Harness & Data**
   - Port CCVS constants, counters, and test result structures.
   - Implement `FieldValue` abstractions (numeric, numeric-edited, alphanumeric).
3. **Phase 2 – Core MOVE Tests**
   - Translate F1-1 through F1-30 (numeric to numeric/numeric-edited) to validate numeric helpers.
   - Use unit tests to assert truncation, scaling, zero padding behaviors.
4. **Phase 3 – Alphanumeric & Alphabetic Moves**
   - Implement F1-31 through F1-56; ensure padding/truncation/insertions match COBOL.
5. **Phase 4 – Limit Tests**
   - Encode F1-57 through F1-60 data-driven loops.
   - Pay special attention to dependency between initial mass MOVE and subsequent verifications; create fixture ensuring state sharing.
6. **Phase 5 – Finalization**
   - Add CLI entry to run whole suite and write `report.log`.
   - Provide golden-file comparison script vs COBOL output.
   - Document steps in README; add Makefile target `make nc104a_py`.

## 7. Testing Strategy
- **Unit Tests:**  
  - Numeric formatting (zero padding, truncation, CR suffix, blank-when-zero).  
  - Edited pictures (currency, commas, check-protect).  
  - Padding/truncation for alphanumeric/alphabetic moves.  
  - Limit-test helper ensuring batch MOVE populates all targets.
- **Integration Tests:**  
  - `pytest -k integration` runs entire Python suite; compare generated `report.log` to baseline using `difflib`.
- **Static Analysis:**  
  - Run `ruff`, `mypy` (optional) to keep codebase clean.

## 8. Tooling & Automation
- Add `Makefile` targets:
  - `make nc104a_py` – run Python translation and produce report.
  - `make nc104a_py_test` – execute pytest suite.
- Optional GitHub Actions workflow to run tests on push.

## 9. Risks & Mitigations
| Risk | Mitigation |
|------|------------|
| **Decimal precision differences** | Configure `decimal.getcontext()` with sufficient precision and rounding (`ROUND_HALF_EVEN` unless COBOL requires otherwise); add regression tests. |
| **Edited picture intricacy** | Implement exhaustive unit tests per edited pattern before integrating into main tests. |
| **Pagination mismatches** | Write snapshot tests verifying header frequency and line counts. |
| **Large test count maintenance** | Use data-driven definitions (list of dicts) and helper factories to avoid manual duplication; keep mapping table referencing original paragraph IDs. |

## 10. Deliverables for Next Agent
1. Python package scaffold with harness, reporter, and data model modules.
2. Implemented MOVE tests up through at least F1-10 demonstrating numeric coverage plus sample alphabetic test.
3. Unit tests for numeric/alphanumeric formatting helpers.
4. CLI entry + instructions in repository README describing how to run and validate results.
5. Script (or Makefile target) that diffs Python-generated `report.log` against COBOL baseline for regression assurance.

Following this plan will equip the next agent to deliver a faithful, maintainable Python translation of NC104A that mirrors the COBOL MOVE Format 1 validation suite.
