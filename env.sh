# Optional portable environment defaults. Source this file, do not execute it.
# Override BEND_HOME/ELAN_HOME before sourcing if your tools live elsewhere.
export BEND_HOME="${BEND_HOME:-$HOME/.bend}"
export ELAN_HOME="${ELAN_HOME:-$HOME/.elan}"
export BEND_NO_TELEMETRY=1
export PATH="$BEND_HOME/bin:$ELAN_HOME/bin:$PATH"
