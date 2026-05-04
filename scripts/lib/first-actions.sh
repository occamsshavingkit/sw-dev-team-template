#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# Shared FIRST ACTIONS detection helpers.

first_actions_step0_recorded() {
  local project_root="$1"
  local notes="$project_root/CUSTOMER_NOTES.md"

  [[ -f "$notes" ]] || return 1

  grep -qiE \
    'issue[- ]feedback opt[- ]in|upstream issue feedback|framework gaps filed upstream' \
    "$notes"
}

first_actions_step0_warning() {
  local project_root="$1"
  local mode="${2:-session}"

  first_actions_step0_recorded "$project_root" && return 0

  case "$mode" in
    upgrade)
      cat <<'EOF'
====================================================================
ACTION REQUIRED: FIRST ACTIONS Step 0 is not recorded.

This project has no CUSTOMER_NOTES.md record for issue-feedback opt-in.
At the next Claude session, tech-lead must ask Step 0 before dispatching
agents or filing framework gaps upstream:

  "Do you want this project to file framework-gap issues upstream?"

Route the customer's answer to researcher for CUSTOMER_NOTES.md recording
under "Issue feedback opt-in". Retroactive opt-in is valid for upgraded
projects.
====================================================================
EOF
      ;;
    *)
      cat <<'EOF'
====================================================================
FIRST ACTIONS pending: Step 0 issue-feedback opt-in is not recorded.

Before dispatching agents or starting project work, tech-lead should ask:

  "Do you want this project to file framework-gap issues upstream?"

Route the answer to researcher for CUSTOMER_NOTES.md recording under
"Issue feedback opt-in".
Type "run first actions" or "start" to begin the Step 0 → Step 3 flow.
====================================================================
EOF
      ;;
  esac
}
