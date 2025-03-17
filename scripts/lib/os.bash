#!/usr/bin/env bash

declare ___OS_RELEASE_FILEPATH="/etc/os-release"
declare ___OS_ID=""
declare ___OS_MACHINE_ARCHITECTURE=""
declare ___OS_KERNEL_NAME=""

function os_echo_architecture_to_amd() {
	local -r architecture="$1"
	case "$architecture" in
	x86_64) echo "amd64" ;;
	esac
}

function os_echo_machine_architecture() {
	if [ -n "$___OS_MACHINE_ARCHITECTURE" ]; then
		echo -n "$___OS_MACHINE_ARCHITECTURE"
		return 0
	fi

	local -r machine_architecture="$(uname --machine)" || exit $?
	___OS_MACHINE_ARCHITECTURE="$machine_architecture"
	echo -n "${machine_architecture}"
}

function os_echo_kernel_name() {
	if [ -n "$___OS_KERNEL_NAME" ]; then
		echo -n "$___OS_KERNEL_NAME"
		return 0
	fi

	local -r kernel_name="$(uname --kernel-name |
		tr '[:upper:]' '[:lower:]')" || exit $?
	___OS_KERNEL_NAME="$kernel_name"
	echo -n "${kernel_name}"
}

function os_echo_id() {
	if [ -n "$___OS_ID" ]; then
		echo -n "$___OS_ID"
		return 0
	fi

	local -r id="$(grep -E "^(ID=)" "$___OS_RELEASE_FILEPATH" |
		cut --fields=2 --delimiter='=' |
		tr --delete '[:punct:]' |
		tr --delete '[:cntrl:]' |
		tr '[:upper:]' '[:lower:]')" || exit $?
	___OS_ID="$id"
	echo -n "${id}"
}

function os_echo_desktop_environment() {
	local -r de="$DESKTOP_SESSION"
	echo -n "$de" | tr --delete '[:punct:]' | tr --delete '[:cntrl:]' | tr '[:upper:]' '[:lower:]'
}

function os_query_release_file() {
	local key="$1"
	local -r result="$(grep -E "^($key=)" "$___OS_RELEASE_FILEPATH" |
		cut --fields=2 --delimiter='=' |
		tr --delete '[:punct:]' |
		tr --delete '[:cntrl:]' |
		tr '[:upper:]' '[:lower:]')" || exit $?
	echo -n "${result}"
}
