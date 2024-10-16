#!/bin/sh
####################################################
# Remote Power Framework
#
# SPDX-License-Identifier: GPL-3.0
# 2023-2024 (C) Philip Oberfichtner <pro@denx.de>
####################################################

set -e

THIS_SCRIPT="$0"
CFG_FILE="${THIS_SCRIPT}.cfg"

cat_cfg() {
	# Ignore empty lines and comments
	sed '/^$/d ; /^#/d' < ${CFG_FILE}
}

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

	# The following construct is a bit odd. I would have preferred to use
	#
	# 	cat_cfg | while read ...
	#
	# But, apparently, in that case, 'while' opens a subshell, such that the
	# return statement does not have the desired effect.
	#
	# The following here-document-construct resolves the issue. See this
	# post for more information:
	# https://stackoverflow.com/questions/16854280/a-variable-modified-inside-a-while-loop-is-not-remembered#16855194
	done <<-EOF
		$(cat_cfg)
	EOF

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

do_reset () {
	do_cmd off
	sleep 5
	do_cmd on
}

do_forall () {
	cat_cfg | while read addr name ; do
		${THIS_SCRIPT} "${name}" "$1" || true
	done
}

if [ "$1" = "list" ]; then
	printf "\n%s\t%s\n\n" address target
	cat_cfg
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
