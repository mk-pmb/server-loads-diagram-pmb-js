#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function img2base64px_lite () {
  echo "# no header ($FUNCNAME)"
  local SRC_FN="$1"; shift
  convert "$SRC_FN" -colorspace RGB -depth 8 "$@" ppm:- \
    | grep -Faxe 255 -A 900210 | tail -n +2 | base64 --wrap=0 | sed -re '
    s~...=$~~    # cut-off partial pixels'
  return 0
}










[ "$1" == --lib ] && return 0; img2base64px_lite "$@"; exit $?
