#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function img2colorscale () {
  local SELFPATH="$(readlink -m "$BASH_SOURCE"/..)"
  local SRC_FN="$1"; shift

  case "$SRC_FN" in
    --recover )
      local SCALE="$(grep -havFe '#' -- "$@")"
      local SIZE="$(<<<"$SCALE" base64 --decode | tr -c : : | wc -L)"
      let SIZE="${SIZE:-0} / 3"
      printf '%s\n' P6 "$SIZE 100" 255
      for SIZE in {1..100}; do
        <<<"$SCALE" base64 --decode || return $?
      done
      return 0;;
  esac

  [ -n "$SRC_FN" ] || SRC_FN="$SELFPATH"/scale-colors.svg
  [ -f "$SRC_FN" ] || return 4$(
    echo "E: $FUNCNAME: cannot find source image file: $SRC_FN" >&2)
  local IMCK_OPS=( -crop '100%x1+0+0' )

  local SCALE="$LOADBARS_SCALE"
  if [ -n "$SCALE" ]; then
    IMCK_OPS+=( -scale "${SCALE}%x1+0+0" )
  fi

  "$SELFPATH"/shims/img2base64px.lite.sh "$SRC_FN" "${IMCK_OPS[@]}" \
     | tail -n +2 | tr -d '\n'
  PIPE_RV="${PIPESTATUS[*]}"
  let PIPE_RV="${PIPE_RV// /+}"
  [ "$PIPE_RV" == 0 ] || return "$PIPE_RV"
}










[ "$1" == --lib ] && return 0; img2colorscale "$@"; exit $?
