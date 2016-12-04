#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function ex01_gen_logs () {
  local SELFPATH="$(readlink -m "$BASH_SOURCE"/..)"
  cd "$SELFPATH" || return $?

  local LOG_FN=
  local LOG_LN=
  local DAY_NUM=
  local MM_HOUR=
  local MM_MIN=
  local MM_LOAD=0
  local SERIAL=0
  local DATA_DAYS=5
  for DAY_NUM in $(seq 0 $DATA_DAYS); do
    LOG_FN="ex01-day-$DAY_NUM.txt"
    echo -n $'    \r'"create $LOG_FN: "
    >"$LOG_FN" || return $?
    for MM_HOUR in {0..23}; do
      for MM_MIN in $(seq 0 2 59); do
        let SERIAL="$SERIAL+1"

        # decays
        let MM_LOAD="$MM_LOAD - 2"
        [ $MM_LOAD -ge 0 ] || MM_LOAD=0
        let MM_LOAD="($MM_LOAD * 95) / 100"
        [ $MM_LOAD -ge 200 ] && let MM_LOAD="($MM_LOAD * 75) / 100"

        # add new loads
        [ $MM_HOUR == 2 -a $MM_MIN -le 20 -a $MM_LOAD -lt 150 ] \
          && let MM_LOAD="$MM_LOAD+$MM_MIN"
        [ $(( $SERIAL % 7 )) == 0 ] \
          && let MM_LOAD="$MM_LOAD + (($SERIAL % 4) * 10)"
        [ $(( $SERIAL % 50 )) == $MM_MIN ] && let MM_LOAD="$MM_LOAD+15"
        [ $(( $SERIAL % 400 )) -le 8 ] && let MM_LOAD="$MM_LOAD+10"
        [ $(( $SERIAL % 2300 )) == 999 ] && MM_LOAD='4200'

        LOG_LN="$(printf '%02g:%02g [...] 15/5/1: 0%% %g%% 0%% up: 0:00\n' \
          "$MM_HOUR" "$MM_MIN" "$MM_LOAD")"
        # [ "$MM_LOAD" == 0 ] || echo "$LOG_LN"
        echo "$LOG_LN"
      done
    done >>"$LOG_FN" || return $?
  done
  echo 'done.'

  SERIAL=0
  for LOG_FN in 2010-{07..08}-{01..31}.txt; do
    echo -n $'    \r'"symlink $LOG_FN: "
    [ -L "$LOG_FN" ] && rm -- "$LOG_FN"
    let SERIAL="($SERIAL + 1) % $DATA_DAYS"
    ln --symbolic --no-target-directory -- "ex01-day-$SERIAL.txt" "$LOG_FN"
  done
  echo 'done.'

  return 0
}










[ "$1" == --lib ] && return 0; ex01_gen_logs "$@"; exit $?
