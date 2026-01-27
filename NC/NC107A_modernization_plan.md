# NC107A Modernization Plan (COBOL ➜ Python)

## 1. Objectives & Constraints
- **Primary Goal:** Produce a faithful Python translation of NC107A that validates figurative constants, continuation lines, separators, JUSTIFIED, SYNCHRONIZED, BLANK WHEN ZERO, REDEFINES, VALUE/USAGE clauses, currency/decimal-point settings, numeric paragraph names, and CONTINUE semantics exactly as the COBOL original.
- **Constraints:**  
  - Preserve CCVS harness behavior: pass/fail/delete/inspect counters, pagination, headings, ANSI references, and `report.log` formatting.  
  - Maintain original data values, literal lengths, table shapes, and test ordering to keep regression comparisons straightforward.  
  - Python implementation must coexist with COBOL version; no changes to COBOL beyond this plan.

## 2. High-Level Architecture Mapping
| COBOL Concept                              | Python Equivalent                                               |
|-------------------------------------------|-----------------------------------------------------------------|
| Divisions/Sections/Paragraphs             | Package modules (`harness`, `tests`, `data`, `reporter`).       |
| WORKING-STORAGE data items                | `dataclasses`/typed containers (`Decimal`, `str`, `Enum`).      |
| CCVS harness (PASS/FAIL logging)          | `TestHarness` class with reporter abstraction.                  |
| PRINT-FILE                                 | `reporter.py` writing to `report.log` with pagination logic.    |
| PERFORM/GO TO sequences                    | Explicit function calls, loops, or dispatch tables.             |
| Figurative constants, BLANK WHEN ZERO      | Helper utilities emulating COBOL move/padding semantics.        |
| REDEFINES structures                       | Python dataclasses with shared memory modeled via `bytearray` or helper views. |
| VALUE clause OCCURS tables                 | Nested lists/dicts with initializer functions.                  |

## 3. Proposed Python Package Layout
```
nc107a/
  __main__.py          # CLI entry (python -m nc107a)
  harness.py           # CCVS emulation (counters, PASS/FAIL, record writer)
  reporter.py          # Header/footer templates, pagination logic
  state.py             # Working-storage initialization (dataclasses/constants)
  figurative.py        # Helpers for ZERO, SPACE, QUOTE, HIGH-/LOW-VALUE, currency
  continuation.py      # Utilities validating multi-line literals & offsets
  tests/
      figurative_tests.py
      continuation_tests.py
      separator_tests.py
      justified_tests.py
      sync_blank_tests.py
      redef_usage_value_tests.py
      currency_decimal_tests.py
      numeric_paragraph_tests.py
      continue_tests.py
  resources/
      headings.py      # CCVS constant strings
```

## 4. Data Modeling Strategy
1. **Numeric/Edited Fields:**  
   - Use `decimal.Decimal` with context precision ≥ 20 digits.  
   - Create `NumericField` helper capturing picture length, scale, sign, blank-when-zero rules, and currency symbol handling (`"W"`).  
   - Provide formatters for `DECIMAL-POINT IS COMMA` so `to_display()` inserts commas as decimal separators.

2. **Alphanumeric/Alphabetic Fields:**  
   - Represent as strings but wrap with `AlphaField` enforcing length, justification, and synch attributes (simulate `JUSTIFIED RIGHT`, `SYNCHRONIZED RIGHT`).  
   - Implement `move(source, target)` that handles truncation/padding logic.

3. **REDEFINES Modeling:**  
   - Back fields with `bytearray` segments and create view classes that interpret bytes in different ways (numeric/alphabetic).  
   - Provide helper to read/write slices to maintain cross-field consistency.

4. **Tables & OCCURS:**  
   - Initialize `VALUE-TABLE` as `[[ "AZ" for _ in range(10)] for _ in range(10)]`.  
   - Track loop indices (SUB1/SUB2) in the harness state for parity with COBOL tests.

5. **Metadata:**  
   - Store feature names, ANSI references, and remarks within each test definition to mirror COBOL output.

## 5. Execution & Control Flow
1. **Harness**
   - Methods: `pass_test(test_case)`, `fail_test(test_case, computed, correct, remark)`, `delete_test`, `inspect_test`.  
   - Maintain counters, record count, current paragraph name, dot suffix (REC-CT), and computed/correct buffers.  
   - Expose `run_tests(test_sequence)` which iterates ordered `TestCase` objects.

2. **Test Definitions**
   - Each test represented by `TestCase` dataclass containing: `name`, `feature`, `ansi_ref`, `setup(state)`, `execute(state)`, `assertions(state)` returning `PassResult` or `FailResult`.  
   - Group tests by feature (figurative constants, separators, etc.) to keep modules manageable and mimic COBOL ordering.

3. **Continuation & Literal Validation**
   - Implement helper to reconstruct COBOL multi-line literals (with hyphen continuation) and verify actual Python strings match expected sequences.

4. **Numeric Paragraph Names**
   - Use dispatch map keyed by integers (e.g., `{3: paragraph_3, 4: paragraph_4}`) to emulate `GO TO 3 4 5 DEPENDING ON ...`.  
   - For PERFORM THRU/TIMES blocks, use Python loops but keep instrumentation (increment `num_utility`) identical.

5. **Reporting**
   - `Reporter` handles headers (CCVS-H-1..H-3), column names, hyphen line, detail records, fail info, bail-out info, and end-of-test summaries (CCVS-E-*).  
   - Maintain pagination (42 lines/page) and replicate `WRITE-LINE`/`WRT-LN` semantics.

## 6. Testing & Verification Strategy
- **Unit Tests**
  - Field helpers: justification alignment, blank-when-zero behavior, currency insertion, decimal comma formatting, figurative constant mapping.
  - REDEFINES view: ensure shared storage updates propagate.
  - Continuation parser: verify multi-line literal assembly.

- **Integration Tests**
  - Run entire Python suite, generate `report.log`, and diff against COBOL output (store golden file).  
  - Validate counter totals (pass/fail/delete/inspect) and page break lines.

- **Static Analysis**
  - Use `pytest` for tests, `ruff` for linting, `mypy` (optional) for type checking.

## 7. Incremental Roadmap
1. **Phase 0 – Scaffolding:** Set up Python package, harness skeleton, reporter with hard-coded headers, CLI entry.
2. **Phase 1 – Data Layer:** Implement working-storage dataclasses, figurative constant helpers, justification logic, REDEFINES backing store.
3. **Phase 2 – Core Feature Tests:** Port FIG, CONTINUATION, SEPARATOR, JUSTIFIED sections to validate harness + data interactions.
4. **Phase 3 – Specialized Behaviors:** Implement SYNCHRONIZED, BLANK WHEN ZERO, currency/decimal-comma, numeric paragraph names, and CONTINUE statement tests.
5. **Phase 4 – REDEFINES/USAGE/VALUE:** Translate complex REDEFINES sections and OCCURS value checks, ensuring nested data updates reflect COBOL semantics.
6. **Phase 5 – Finalization:** Complete remaining tests, ensure all ANSI references/remarks set, add CLI/Makefile target (`make nc107a_py`), and document run instructions.
7. **Phase 6 – Regression Assurance:** Generate Python `report.log`, compare with COBOL baseline in CI workflow, and document known deviations (if any).

## 8. Deliverables for Next Agent
- Python project skeleton with harness/reporter scaffolding and initial tests implemented.
- Data model module covering key fields (figurative constants, justification groups, REDEFINES storage).
- Initial test modules (FIG/CONTINUATION/JUSTIFIED) demonstrating translation approach.
- Unit tests for helpers plus integration test harness comparing reports.
- Documentation (README section) describing how to run Python translation, how data structures map to COBOL, and how to extend remaining tests.

Following this plan will enable a maintainable, testable Python translation of NC107A that preserves the original program’s validation intent while adopting modern software engineering practices.
