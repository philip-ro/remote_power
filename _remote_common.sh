#!/bin/sh
#############################################
# Remote Power Framework
#
# SPDX-License-Identifier: GPL-3.0
# 2023 (C) Philip Oberfichtner <pro@denx.de>
#############################################
#
#
# This script provides a framework for remotely switching devices on and off,
# like USB ports or WiFi sockets. All an implementation has to do, is to define
# the `send_request()` function and define a mapping from human-readable names
# to device addresses. For example:
#
#
#   +--------------------------------------------------+
#   |              File: remote_usb                    |
#   +----+---------------------------------------------+
#   |  1 | #!/bin/sh                                   |
#   |  2 |                                             |
#   |  3 | send_request() {                            |
#   |  4 |         local addr="$1"                     |
#   |  5 |         local cmd="$2"                      |
#   |  6 |                                             |
#   |  7 |         switch_usb ${addr} ${cmd}           |
#   |  8 |                                             |
#   |  9 |         if [ error ]; then                  |  The error message will
#   | 10 |                 echo "ERROR such and such"  |  be caught and printed
#   | 11 |                 return 1                    |  by the framework
#   | 12 |         fi                                  |
#   | 13 |                                             |
#   | 14 |         if [ usb_is_on ]; then              |  It's important to echo
#   | 15 |                 echo on                     |  the current state of
#   | 16 |         else                                |  the device. An
#   | 17 |                 echo off                    |  unexpected state makes
#   | 18 |         fi                                  |  the script fail.
#   | 19 | }                                           |
#   | 20 |                                             |
#   | 21 | . $(dirname $0)/_remote_common.sh           |
#   +----+---------------------------------------------+
#
#   Hereby the command, ${2}, can either be "on", "off" or "status", likewise
#   the value `echo`ed by `send_request()`.
#
#   +---------------------------------------------------+
#   |              File: remote_usb.cfg                 |
#   +----+----------------------------------------------+
#   |  1 | 6-1.4.1 port-1                               |
#   |  2 | 6-1.4.2 port-2                               |
#   |  3 | 6-1.4.3 port-3                               |
#   |  4 | 6-1.4.4 port-4                               |
#   +----+----------------------------------------------+
#
# The first column of remote_usb.cfg, 6-1.4.X, is used as the address argument
# ${1} for send_request(). The second column is used as command line argument
# for the remote_usb script.
#
# Finally, lets have a look at the most common usage examples:
#
#	remote_usb --help
#	remote_usb list
#	remote_usb port-2 on
#	remote_usb port-2 reset
#	remote_usb port-2 off
#	remote_usb all off
#

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
	reset)	do_cmd off && sleep 5 && do_cmd on;;
	*)	echo "ERROR: Unknown Command!"; exit 1;;
esac
