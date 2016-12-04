#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function ex01_gen_diag () {
  local SELFPATH="$(readlink -m "$BASH_SOURCE"/..)"
  cd "$SELFPATH" || return $?

  local LOGS2PNG='../../loadbars.sh'
  local M_CMD=()
  local MONTH=
  for MONTH in 10-{07..08}; do
    M_CMD=(
      env LOADBARS_JS_PATH="${LOGS2PNG%.sh}.js"
      "$LOGS2PNG" "${MONTH//-/}"
      )
    echo "render month 20$MONTH (shell command: ${M_CMD[*]}) …"
    "${M_CMD[@]}" || return $?
    echo -n "probably result file(s): "
    ls "20$MONTH"*.html
  done

  return 0
}










[ "$1" == --lib ] && return 0; ex01_gen_diag "$@"; exit $?
