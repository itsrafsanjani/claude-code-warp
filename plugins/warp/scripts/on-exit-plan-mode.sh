#!/bin/bash
# Hook script for Claude Code PreToolUse event on ExitPlanMode
# Sends a structured Warp notification when Claude finishes planning and is
# waiting for the user to approve the plan, transitioning the session status
# to Blocked until the user responds.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/should-use-structured.sh"

# No legacy equivalent for this hook
if ! should_use_structured; then
    exit 0
fi

source "$SCRIPT_DIR/build-payload.sh"

# Read hook input from stdin
INPUT=$(cat)

# Plan content is markdown. Use the first non-empty line as the summary so the
# notification surfaces the plan title rather than raw markdown.
PLAN=$(echo "$INPUT" | jq -r '.tool_input.plan // ""' 2>/dev/null)
SUMMARY=$(echo "$PLAN" | awk 'NF { sub(/^#+ */, ""); print; exit }')
[ -z "$SUMMARY" ] && SUMMARY="Claude is waiting for plan approval"

# Truncate for notification display
if [ ${#SUMMARY} -gt 200 ]; then
    SUMMARY="${SUMMARY:0:197}..."
fi

BODY=$(build_payload "$INPUT" "question_asked" \
    --arg summary "$SUMMARY")

"$SCRIPT_DIR/warp-notify.sh" "warp://cli-agent" "$BODY"
