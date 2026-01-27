#!/usr/bin/env bash
# Run NC COBOL tests. Produces report.txt (summary) and report.log (last program's
# test log). Requires: cobj (COBOL compiler), java, perl. Run from project root.
#
# Full suite:  ./run-nc.sh
# Or manually: cd NC && perl ../report.pl --keep-report-log
#
# Single program (keeps report.log for that program):
#   cd NC && cobj -jar -std=cobol85 NC101A.CBL && java -cp .:${CLASSPATH:-} NC101A
#   (Use NC109M.DAT for NC109M: ... NC109M < NC109M.DAT)

set -e
cd "$(dirname "$0")/NC"

# Ensure GnuCOBOL uses its Homebrew config, not any leftover opensourcecobol4j env
unset COB_CONFIG_DIR COB_COPY_DIR COB_JAVA_FLAGS CLASSPATH

export COB_SWITCH_1=ON
export COB_SWITCH_2=OFF
perl ../report.pl --keep-report-log
echo "--- report.txt (summary) ---"
cat report.txt
echo ""
echo "--- report.log (last program log) ---"
cat report.log 2>/dev/null || true
