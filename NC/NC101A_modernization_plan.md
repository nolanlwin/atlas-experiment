# NC101A Modernization Plan (COBOL → Python)

## 1. Goals & Constraints
- **Primary Goal:** Re-implement the NC101A COBOL validation program in Python while preserving functional parity and test coverage of all multiply/size-error scenarios.
- **Constraints:**  
  - Maintain test semantics (pass/fail counters, reporting).  
  - Keep existing test data values and rounding behavior identical.  
  - Produce human-readable logs equivalent to `report.log`.

## 2. High-Level Architecture Mapping
| COBOL Concept                     | Python Equivalent                                               |
|----------------------------------|-----------------------------------------------------------------|
| Division/Section structure       | Modules + classes/functions with clear responsibilities.        |
| WORKING-STORAGE tables           | `dataclasses`/named tuples or module-level constants/dicts.     |
| PERFORMed paragraphs (tests)     | Individual test functions grouped in classes or dictionaries.  |
| PRINT-FILE + WRITE-LINE          | Logger abstraction writing to text file (e.g., `logging`).     |
| Global counters (pass/fail/etc.) | State object encapsulating counters and record formatting.      |
| Size-error behavior              | Custom arithmetic helpers with overflow/rounding simulation.    |

## 3. Translation Strategy
1. **Data Modeling**
   - Create Python representations of all literal data (e.g., dictionaries of constants, `Decimal` values for numeric literals).
   - Use `decimal.Decimal` with appropriate context to mimic COBOL precision/rounding.
2. **Execution Engine**
   - Implement a `TestHarness` class encapsulating counters, record count, formatting, and output.
   - Map COBOL sections (INIT/TEST/FAIL/WRITE) into Python methods maintaining sequence.
3. **Arithmetic Helpers**
   - Build reusable helpers for multiply operations that accept operands, rounding flags, and size constraints; raise custom `SizeError` exceptions when limits exceeded.
   - Support multiple result targets and ON SIZE ERROR / NOT ON SIZE ERROR semantics.
4. **Test Definitions**
   - Encode each MPY test as structured data (e.g., list of dicts) defining:
     - Initialization steps.
     - Operation parameters (operands, rounding, size-error hooks).
     - Expected outcomes (field values, flags, remarks).
   - Iterate through definitions to execute and log results, reducing duplicated code.
5. **Reporting Layer**
   - Recreate headings/hyphen lines via template strings.
   - Store results in memory, flush to `report.log` via context manager at end.

## 4. Detailed Task Breakdown
1. **Scaffold Project**
   - Create Python package `nc101a` with `__main__.py` for CLI entry.
   - Add `requirements.txt` (e.g., `decimal` is stdlib; no extra deps expected).
2. **Implement Core Modules**
   - `models.py`: Data classes for fields, test cases, results.
   - `arith.py`: Decimal context setup, multiply/size-error helpers.
   - `reporter.py`: Handles record formatting and writing.
   - `tests.py`: Definitions for each MPY test (1–29) referencing shared helpers.
   - `runner.py`: Orchestrates initialization, execution, and summary output.
3. **Port Data Definitions**
   - Translate WORKING-STORAGE literals into Python constants with explicit precision.
   - Document any assumptions (e.g., signed vs unsigned, picture sizes).
4. **Recreate Control Flow**
   - For each COBOL paragraph (INIT, TEST, FAIL), write equivalent Python functions.
   - Use exceptions or return codes to handle early exits (e.g., GO TO).
5. **Logging and Output**
   - Ensure the Python program writes identical headings and lines to `report.log`.
   - Keep pass/fail counters synchronized with operations.
6. **Validation & Testing**
   - Add unit tests verifying arithmetic helper behavior (rounded/not, size errors).
   - Create integration test comparing Python `report.log` to expected golden file.
7. **Documentation & Tooling**
   - Document how to run the Python version, required Python version (>=3.11), and testing commands.
   - Optionally add `Makefile` target for running the Python translation + tests.

## 5. Risk Mitigation
- **Decimal Precision:** Configure `decimal.getcontext()` with sufficient precision (≥34 digits) and `ROUND_HALF_UP` to emulate COBOL rounding rules.
- **Size Boundaries:** Explicitly encode COBOL PIC limits; write unit tests that confirm overflow triggers `SizeError`.
- **Flow Control Differences:** Map GO TO chains via structured code paths; leverage helper functions to avoid deeply nested `if` statements.
- **Regression Assurance:** Use diff-based comparison of generated logs to confirm behavior matches COBOL output.

## 6. Incremental Roadmap
1. **Phase 1:** Set up project skeleton, decimal context, and logging infrastructure.
2. **Phase 2:** Port foundational data definitions and implement arithmetic helper APIs.
3. **Phase 3:** Translate a small subset of MPY tests end-to-end to validate approach.
4. **Phase 4:** Encode remaining tests programmatically (data-driven definitions).
5. **Phase 5:** Add CLI entry point, finalize reporting, and ensure parity with COBOL output.
6. **Phase 6:** Write automated tests, documentation, and CI hooks (if applicable).

## 7. Deliverables for Next Agent
- Python package structure with placeholder modules.
- Implemented decimal configuration and multiply helper prototypes.
- Draft of test case data structure for first MPY tests.
- Script to run the Python version and produce `report.log`.
- Documentation describing how to extend/add tests and verify outputs.

Following this plan will produce a maintainable, testable Python translation that mirrors the original COBOL NC101A functionality while adopting modern software engineering practices.
