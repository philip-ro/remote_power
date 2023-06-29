#!/bin/sh
#############################################
# Remote Power Framework
#
# SPDX-License-Identifier: GPL-3.0
# 2023 (C) Philip Oberfichtner <pro@denx.de>
#############################################

set -e

THIS_SCRIPT="$0"
CFG_FILE="${THIS_SCRIPT}.cfg"

usage () {
	local script_name=$(basename ${THIS_SCRIPT})

	printf "\nUsage:
	${script_name}                - get status for all targets
	${script_name} list           - list available targets
	${script_name} all <cmd>      - do <cmd> for all targets
	${script_name} <target> <cmd> - do <cmd> for <target>
	\n
	<cmd> can be \"on\", \"off\", \"reset\" or \"status\"
	\n"
}

name_to_addr () {
	while read addr name ; do
		if [ "${name}" = "${TARGET}" ]; then
 			echo ${addr}
			return 0
		fi
	done < ${CFG_FILE}
 
	printf 'Target "%s" not found!\n' "${TARGET}" >&2
	return 1
}

print_status() {
	local status="$1"

	case "${status}" in
		 on)	# bold blue
			printf "\033[1;34m"
			;;
		off)	# normal white
			;;
		*)	# bold red
			printf "\033[1;31m"
	esac

	printf "%-10s %s\n" "${TARGET}" "${status}"
	printf "\033[0m" # reset color
}

do_cmd () {
	local addr cmd res
	cmd="$1"
	addr="$(name_to_addr)"

	res=$(send_request "${addr}" "${cmd}") || true

	if [ "${cmd}" = "status" ]; then
		[ -z "${res}" ] && res="ERROR: Unknown status"
		print_status "${res}"
		return
	fi

	if [ "${res}" != "${cmd}" ]
	then
		echo "ERROR: Result \"${res}\" is unexpcted!" >&2
		return 1
	fi

	return 0
}

function_exists() {
	type "$1" > /dev/null 2>&1
}

do_reset () {
	# Some implementations require additional work to be done for the
	# reset to be effective. This can be achieved by optionally implementing
	# reset_{pre,post}_hook.

	do_cmd off
	function_exists "reset_pre_hook"  && reset_pre_hook

	sleep 5

	function_exists "reset_post_hook" && reset_post_hook
	do_cmd on
}

do_forall () {
	while read addr name ; do
		${THIS_SCRIPT} "${name}" "$1" || true
	done < ${CFG_FILE}
}

if [ "$1" = "list" ]; then
	printf "\n%s\t%s\n\n" address target
	cat ${CFG_FILE}
	printf "\n"
	exit
fi

case $# in
	0)
		TARGET=all
		CMD=status
		;;
	2)
		TARGET=$1
		CMD=$2
		;;
	*)
		usage
		exit
		;;
esac

if [ "${TARGET}" = "all" ]; then
	do_forall "${CMD}"
	exit
fi

case "${CMD}" in
	on|off|status) do_cmd ${CMD};;
	reset)	do_reset;;
	*)	echo "ERROR: Unknown Command!"; exit 1;;
esac
