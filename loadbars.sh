#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function loadbars_days () {
  local SELFPATH="$(readlink -m "$BASH_SOURCE"/..)"
  # cd "$SELFPATH" || return $?

  local COLORMAP_PXB64=
  loadbars_check_rebuild_cache || return $?

  local COLOR_OVER="$(echo -ne '\x00\x00\x00' | base64)"
  local COLOR_NULL="$(echo -ne '\x55\xAA\xFF' | base64)"
  local BLOCK_DIMS_PX=( 2 2 )

  local ARG=
  for ARG in "$@"; do
    case "$ARG" in
      --recache )
        rm -- "$SELFPATH"/cache/*.{sed,b64} 2>/dev/null
        loadbars_check_rebuild_cache || return $?;;
      [0-9][0-9][0-9][0-9] )
        loadbars_month_report_html "$ARG" || return $?;;
      *.txt )
        loadbars_render_one_day "$ARG" || return $?;;
      * ) echo "E: unsupported option: $ARG"; return 2;;
    esac
  done

  return 0
}


function loadbars_check_rebuild_cache () {
  local CHCD="$SELFPATH/cache"
  mkdir -p "$CHCD" || return $?

  local CHCF="$CHCD/inline.sed"
  local SED_CMD=
  if [ ! -s "$CHCF" ]; then
    printf '%s\n' \
      's~^(\s*<)link( id="loadbars-css" type\S+) [^<>]*>~\1style\2>'"$(
        loadbars_webcode2sed "$SELFPATH/loadbars.css")</style>~" \
      's~^(\s*<script id="loadbars-js" type\S+*) src="//inline">~\1>'"$(
        loadbars_webcode2sed "$SELFPATH/loadbars.js")~" \
        >"$CHCF" || return $?
  fi

  CHCF="$LOADBARS_COLORS"
  if [ -z "$CHCF" ]; then
    CHCF="$CHCD"/colors.b64
    [ -s "$CHCF" ] || "$SELFPATH"/img2colorscale.sh >"$CHCF" || return $?
  fi
  COLORMAP_PXB64="$(cat -- "$CHCF")"
  [ -n "$COLORMAP_PXB64" ] || return 5$(
    echo "E: failed to read color map: $CHCF" >&2)

  return 0
}


function loadbars_webcode2sed () {
  local SRC_FN="$1"; shift
  local SED_TRIM='s~\s+~ ~g;s~^\s+~~;s~\s+$~~'
  LANG=C sed -re "$SED_TRIM"'
    1s~^\xEF\xBB\xBF~~  # strip UTF-8 BOM
    s~\\|\&~\\&~g
    \:^/[/*]:d' -- "$SRC_FN" | tr -s '\n ' ' ' | sed -re "$SED_TRIM"
}


function loadbars_ser2hhmm () {
  local SMIN="${1:-0}"
  printf '%02g:%02g (ser %s)' $(( $SMIN / 60 )) $(( $SMIN % 60 )) "$SMIN"
}


function loadbars_render_one_day () {
  local SRC_LOG="$1"; shift
  local DEST_FN="$1"; shift
  if [ -z "$DEST_FN" ]; then
    DEST_FN="$(basename "$SRC_LOG" .txt)"
    DEST_FN="${DEST_FN%.log}"
    DEST_FN="${DEST_FN%.loads}"
    DEST_FN+=.png
  fi
  local MEASUREMENTS=()
  readarray -t MEASUREMENTS < <(sed -nre '
    s~^([0-2][0-9]:[0-5][0-9]) \[.*\] 15/5/1:\s*([0-9]+|$\
      )%\s*([0-9]+)%\s*([0-9]+)% up:.*$~\1=\3~p
      ' -- "$SRC_LOG" | LANG=C sort -u)
  local MM_HOUR=
  local MM_SMIN=  # smin = serial minute = minutes since midnight
  local MM_LOAD=
  local LOAD_FULL="${LOADBARS_FULL_LOAD:-100}"
  local PX_COLOR=
  local DIAG_PREV_SMIN=
  local DIAG_SMIN=0
  local DIAG_NEXT_SMIN=0
  local DIAG_INTV=2
  local DAY_PXB64=
  local REPEAT=',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'
  REPEAT="${REPEAT:0:${BLOCK_DIMS_PX[0]}}"
  for MM_LOAD in "${MEASUREMENTS[@]}" 24:00=skip; do
    let DIAG_NEXT_SMIN="$DIAG_SMIN+$DIAG_INTV"
    MM_HOUR="${MM_LOAD%%=*}"
    # echo -n "$MM_HOUR -> "
    MM_SMIN="${MM_HOUR##*:}"
    MM_HOUR="${MM_HOUR%%:*}"
    let MM_SMIN="(60 * ${MM_HOUR#0}) + ${MM_SMIN#0}"
    [ "$MM_SMIN" == "$DIAG_PREV_SMIN" ] && continue$(
      echo "W: $SRC_LOG: unexpected additional data '$MM_LOAD', ignored." >&2)
    if [ "$MM_SMIN" -gt "$DIAG_SMIN" ]; then
      # we'd have expected an earlier time
      if [ "$MM_SMIN" -lt "$DIAG_NEXT_SMIN" ]; then
        # if it's just a little bit ahead, then it's probably our expected
        # entry, just logged a bit late. Let's pretend it arrived on time.
        MM_SMIN="$DIAG_SMIN"
      fi
    fi
    while [ "$MM_SMIN" -gt "$DIAG_SMIN" ]; do
      PX_COLOR="${REPEAT//,/$COLOR_NULL}"
      # echo "$DIAG_SMIN: $PX_COLOR $(loadbars_b64hex "${PX_COLOR:0:4}")"
      DAY_PXB64+="$PX_COLOR"
      DIAG_PREV_SMIN="$DIAG_SMIN"
      DIAG_SMIN="$DIAG_NEXT_SMIN"
      let DIAG_NEXT_SMIN="$DIAG_SMIN+$DIAG_INTV"
    done
    MM_LOAD="${MM_LOAD##*=}"
    # echo "@ $MM_SMIN : $MM_LOAD"
    [ "$MM_LOAD" == skip ] && continue
    if [ "$MM_SMIN" != "$DIAG_SMIN" ]; then
      MM_HOUR="$(loadbars_ser2hhmm "$MM_SMIN")"
      echo "W: $SRC_LOG: expected $(loadbars_ser2hhmm "$DIAG_SMIN"
        ) but found $MM_HOUR='$MM_LOAD' (next: $DIAG_NEXT_SMIN)" >&2
      continue
      printf '%s\n' "${MEASUREMENTS[@]}" | grep -nC 1 \
        -Fe "${MM_HOUR:0:5}=" >&2
      return 3
    fi
    let PX_COLOR="(($MM_LOAD * 100) / $LOAD_FULL) * 4"
    PX_COLOR="${COLORMAP_PXB64:$PX_COLOR:4}"
    # PX_COLOR="$(loadbars_dec2chr "$MM_LOAD" "$MM_LOAD" "$MM_LOAD" | base64)"
    [ -n "$PX_COLOR" ] || PX_COLOR="$COLOR_OVER"
    PX_COLOR="${REPEAT//,/$PX_COLOR}"
    # echo "$DIAG_SMIN: $PX_COLOR $(loadbars_b64hex "${PX_COLOR:0:4}")"
    DAY_PXB64+="$PX_COLOR"
    DIAG_PREV_SMIN="$DIAG_SMIN"
    DIAG_SMIN="$DIAG_NEXT_SMIN"
  done
  REPEAT=',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'
  REPEAT="${REPEAT:0:${BLOCK_DIMS_PX[1]}}"
  local DAY_WIDTH=$(( ( $DIAG_SMIN / $DIAG_INTV ) * ${BLOCK_DIMS_PX[0]} ))
  ( echo P6
    echo "$DAY_WIDTH ${BLOCK_DIMS_PX[1]}"
    echo 255
    echo "${REPEAT//,/$DAY_PXB64}" | base64 --decode
    # yes | tr -c '\0' '\0' | head -c 2k
  ) | convert ppm:- "$DEST_FN"
}


function loadbars_b64hex () {
  <<<"$*" base64 --decode | od -An -t x1
}


function loadbars_dec2chr () {
  perl -e 'map { printf chr ($_ % 256) } @ARGV;' -- "$@"
}


function loadbars_month_report_html () {
  local YEAR_MONTH="$1"; shift
  local SRCFN_TPL="$1"; shift

  [ "${#YEAR_MONTH}" == 4 ] || return 4$(
    echo "E: year+month must be given as four digits: YYMM" >&2)
  local YEAR="20${YEAR_MONTH:0:2}"
  local MONTH="${YEAR_MONTH:2:2}"

  local WEEKDAY_IDX="$(   # 0-6 = sun-sat
    LANG=C date +'%w' --date="$YEAR-$MONTH-01")"
  [ -n "$WEEKDAY_IDX" ] || return 8
  let WEEKDAY_IDX="($WEEKDAY_IDX + 6) % 7"  # converts to 0=mon..6=sun

  local LAST_DAY="$(date +%F --date="$YEAR-$MONTH-01 + 33 days")"
  LAST_DAY="$(date +%d --date="${LAST_DAY%-*}-01 - 1 day")"

  [ -n "$SRCFN_TPL" ] || SRCFN_TPL='%F.txt'

  local MONTH_DATA=
  local DAY_NUM=
  local DAY_PIC=
  local FULL_DATE=
  local DATA_DAYS=0
  local DAY_LOG=
  for DAY_NUM in {01..31}; do
    [ "${DAY_NUM#0}" -gt "$LAST_DAY" ] && continue
    # [ "$WEEKDAY_IDX" == 0 ] && echo; echo -n "    $DAY_NUM:$WEEKDAY_IDX"

    FULL_DATE="$YEAR-$MONTH-$DAY_NUM"
    DAY_LOG="$SRCFN_TPL"
    DAY_LOG="${DAY_LOG//%Y/$YEAR}"
    DAY_LOG="${DAY_LOG//%F/$FULL_DATE}"
    DAY_LOG="${DAY_LOG//%%/%}"
    DAY_PIC=
    if [ -f "$DAY_LOG" ]; then
      # echo -n $'\r'"render $DAY_LOG: "
      DAY_PIC="$(loadbars_render_one_day "$DAY_LOG" png:- | base64 --wrap=0)"
      [ -n "$DAY_PIC" ] || return 6$(echo "E: failed to render $DAY_LOG" >&2)
      let DATA_DAYS="$DATA_DAYS+1"
    fi
    MONTH_DATA+='a\    '"$FULL_DATE:$WEEKDAY_IDX:png:$DAY_PIC"$'\n'

    # next weekday
    let WEEKDAY_IDX="($WEEKDAY_IDX + 1) % 7"
  done
  [ "$DATA_DAYS" -ge 1 ] || return 8$(echo "E: no data for entire month" \
    "$YEAR-$MONTH, using log file names like '$DAY_LOG'" >&2)
  local HTML_DEST="$YEAR-$MONTH-99.diag.html"
  sed -rf <(echo '
    s~\&\$year;~'"$YEAR"'~g
    s~\&\$month;~'"$YEAR"'~g
    s~\&\$loadbars-js;~'"${LOADBARS_JS_PATH:-loadbars.js}"'~g
    / id="loadbars-days"[ >]/{'"$MONTH_DATA"'}
    '
    [ "$LOADBARS_JS_PATH" == //inline ] && cat "$SELFPATH"/cache/inline.sed
    ) -- "$SELFPATH/loadbars.tmpl.html" >"$HTML_DEST" || return $?
  # echo "done, $DATA_DAYS days with data: $HTML_DEST"
  return 0
}














[ "$1" == --lib ] && return 0; loadbars_days "$@"; exit $?
