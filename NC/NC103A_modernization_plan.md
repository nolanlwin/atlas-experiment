# NC103A Modernization Plan (COBOL ➜ Python)

## 1. Objectives & Constraints
- **Goal:** Re-implement the NC103A IF/NEXT SENTENCE validation suite in Python while preserving every test scenario’s observable behavior, counters, and printed report lines.
- **Key Constraints:**
  - Maintain parity with COBOL comparisons across numeric, alphabetic, alphanumeric, group, and literal operands (including signed/packed forms and edited pictures).
  - Recreate `report.log` layout (headers, pass/fail records, remarks, ANSI references, pagination semantics).
  - Keep test data values, sequencing, and “NEXT SENTENCE” side effects intact to ensure regression comparability.

## 2. Program Overview
- NC103A focuses on IF statement variants (`EQUAL`, `NOT`, relational operators, `NEXT SENTENCE`, explicit scope terminators) plus mixed data class comparisons.
- Output is produced through a common test harness (CCVS) that tracks counters and prints detail lines per PAR-NAME.
- Data division defines numerous fields with diverse PICTURE clauses, usage (DISPLAY, COMPUTATIONAL), and group structures used to exercise comparison semantics.

## 3. Target Python Architecture
| COBOL Concept                     | Python Representation |
|----------------------------------|------------------------|
| Sections/paragraphs              | Modules & functions (e.g., `tests.compare_equal()`) invoked by a runner. |
| WORKING-STORAGE data             | `dataclasses`, typed dictionaries, or simple module constants; use `decimal.Decimal` for fixed-precision numbers. |
| CCVS test harness                | `TestHarness` class handling counters, ANSI references, remarks, and file output. |
| PRINT-FILE / WRITE-LINE          | `Reporter` abstraction (wraps `pathlib.Path("report.log")`, respects pagination rules). |
| NEXT SENTENCE side effects       | Explicit helper functions to emulate fall-through behavior; e.g., branch functions returning callables for deferred execution. |
| GO TO / PERFORM flow             | Structured Python control flow (loops, functions) with explicit sequencing list.

## 4. Data Modeling Strategy
1. **Numeric & Edited Fields**
   - Use `Decimal` with context precision ≥ 20 digits; create helper to enforce COBOL picture limits/sign handling.
   - Encapsulate edited formats (currency, blank when zero, P scaling) with formatting/parsing utilities to compare values exactly as COBOL would.
2. **Alphabetic/Alphanumeric**
   - Represent as `str`, but centralize collation assumptions (blank < alphabetic) to mimic COBOL comparisons; consider custom comparator if locale differences arise.
3. **Group Items**
   - Model groups as `dataclasses` or nested dictionaries preserving byte order; provide `.to_bytes()` or `.as_string()` helpers for group-level comparison tests.

## 5. Control-Flow Translation
- Build a `tests.py` module containing an ordered list of test case descriptors:
  ```python
  TestCase(
      name="IF--TEST-GF-1",
      feature="COMPARE--EQUAL",
      ansi_ref="V1-89 6.15.4 GR2",
      setup=lambda state: state.assign("IF-D1", Decimal("0")),
      execute=lambda state: state.assert_equal(state["IF-D1"], Decimal("0"))
  )
  ```
- Each descriptor includes:
  - **Setup callable** mirroring `INIT` paragraphs.
  - **Execution callable** performing the IF logic; include hooks for `NEXT SENTENCE` semantics (e.g., raising `NextSentence` exception caught by harness to trigger follow-on statements).
  - **Failure metadata** (expected/computed formatting, custom remarks).
- Provide reusable assertion helpers: `assert_equal`, `assert_not_equal`, `assert_greater`, `assert_less_or_equal`, etc., each handling mixed data types.

## 6. Output & Reporting
- Implement `Reporter` with:
  - Header/footer templates derived from CCVS constants.
  - Pagination logic (42-line pages) replicating COBOL behavior.
  - Methods `write_detail(test_result)` and `write_fail_info(computed, correct, ansi_ref)` to centralize formatting.
- Ensure PASS/FAIL/DELETE/INSPECT counters match COBOL increments; include ability to mark tests as deleted/inspect when necessary.

## 7. Testing & Validation Plan
1. **Unit Tests**
   - Comparator helpers (numeric vs alphanumeric, signed zero handling, group comparisons, edited pictures).
   - Next Sentence emulation (assert that false branch executes subsequent statement).
2. **Integration Tests**
   - Run entire Python suite, capture generated `report.log`, and diff against COBOL baseline.
   - Validate counter totals and end-of-test summary lines.
3. **Static Checks**
   - Use `pytest` + `mypy` (if typing added) + `ruff/flake8` for style consistency.

## 8. Incremental Roadmap
1. **Phase 0 – Skeleton**
   - Create package `nc103a_py` with modules: `__main__.py`, `state.py`, `harness.py`, `reporter.py`, `tests.py`, `comparators.py`.
2. **Phase 1 – Harness & Reporter**
   - Port CCVS headers/footers, implement counters, file writing, pagination.
3. **Phase 2 – Data Definitions**
   - Encode all WORKING-STORAGE items in `state.py`; include parsing/formatting helpers for PIC variants.
4. **Phase 3 – Core Test Execution**
   - Translate initial set of equality tests (GF-1..GF-10) to prove pattern; add assertion helpers.
5. **Phase 4 – Advanced Comparisons**
   - Implement greater/less/not tests, High/Low-value logic, numeric vs alpha interactions, edited picture comparisons.
6. **Phase 5 – NEXT SENTENCE & Scope Terminators**
   - Model scenarios with `NEXT SENTENCE`, explicit END-IF, and GO TO fall-through.
7. **Phase 6 – Group & COMP Data**
   - Handle group-level move/compare cases, comp vs display comparisons.
8. **Phase 7 – Finalization**
   - Complete remaining tests, ensure remarks/ANSI refs match, add CLI entry & documentation, wire up regression diff test.

## 9. Deliverables for Next Agent
- Python project scaffold with harness/reporter implemented and sample tests.
- Comprehensive data model definitions mirroring COBOL fields.
- Comparator/assertion library with unit tests for mixed data class behavior.
- Script/Makefile target (e.g., `make nc103a_py`) to run suite and generate `report.log`.
- Documentation describing how to extend tests, emulate NEXT SENTENCE, and validate against COBOL output.

Following this plan enables a faithful, maintainable Python translation of NC103A that preserves the original IF statement validation semantics while leveraging modern tooling and structure.
