#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function img2base64px_lite () {
  echo "# no header ($FUNCNAME)"
  convert "$@" -colorspace RGB -depth 8 ppm:- | grep -Faxe 255 -A 900210 \
    | tail -n +2 | base64 --wrap=0
  return 0
}










[ "$1" == --lib ] && return 0; img2base64px_lite "$@"; exit $?
