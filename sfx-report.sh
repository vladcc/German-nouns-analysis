#!/bin/bash

function report
{
	local L_GENDER="$1"
	local L_SFX_LST="$2"
	local L_SFX_PERC="$3"
	local L_GENDER_PERC="$4"
	local L_PASSTHROUGH="$5"
	local L_SORT_BY_REV="$6"
	local L_SORT_FLD=""
	local L_SORT_NUM=""
	local L_SORT_REV=""

	case $L_GENDER in
	  "der") L_GENDER_FLD=8 ;;
	  "die") L_GENDER_FLD=9 ;;
	  "das") L_GENDER_FLD=10 ;;
	esac

	if [ "$L_SORT_BY_REV" -ne 0 ]; then
		L_SORT_FLD=11
	else
		L_SORT_FLD="$L_GENDER_FLD"
		L_SORT_NUM="-n"
		L_SORT_REV="-r"
	fi

	echo "$L_GENDER"
	(head -n 1 "$L_SFX_LST"; \
	awk -F';' -v SfxPerc="$L_SFX_PERC" -v GdrPerc="$L_GENDER_PERC" -v GdrFld="$L_GENDER_FLD" '$4 >= SfxPerc && $(GdrFld) >= GdrPerc' "$L_SFX_LST" | \
	awk -f shortest-sfx-from-csv.awk -v PassThrough="$L_PASSTHROUGH" | \
	sort -t';' $L_SORT_NUM $L_SORT_REV -k${L_SORT_FLD},${L_SORT_FLD}) | awk -F';' -vOFS=';' '{--NF; print n++, $0}' | column -s';' -t
	echo""
}

function main
{
	local L_SFX_LST="${1:-sfx-list-full.csv}"
	local L_SFX_PERC="${2:-0.1}"
	local L_GENDER_PERC="${3:-66}"
	local L_SHORTEST_SFX_ONLY="${4:-1}"
	local L_SORT_BY_REV="${5:-0}"

	local L_PASSTHROUGH=""
	if [ "$L_SHORTEST_SFX_ONLY" -eq 1 ]; then
		L_PASSTHROUGH=0
	else
		L_PASSTHROUGH=1
	fi

	echo "Parameter 1: SuffixList      = $L_SFX_LST"
	echo "Parameter 2: SuffixPercent   >= $L_SFX_PERC"
	echo "Parameter 3: GenderPercent   >= $L_GENDER_PERC"
	echo "Parameter 4: ShortestSfxOnly =  $L_SHORTEST_SFX_ONLY"
	echo "Parameter 5: SortBySuffix    =  $L_SORT_BY_REV"
	echo ""

	report "der" "$L_SFX_LST" "$L_SFX_PERC" "$L_GENDER_PERC" "$L_PASSTHROUGH" "$L_SORT_BY_REV"
	report "die" "$L_SFX_LST" "$L_SFX_PERC" "$L_GENDER_PERC" "$L_PASSTHROUGH" "$L_SORT_BY_REV"
	report "das" "$L_SFX_LST" "$L_SFX_PERC" "$L_GENDER_PERC" "$L_PASSTHROUGH" "$L_SORT_BY_REV"
}

main "$@"
