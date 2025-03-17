#!/bin/bash

function log() {
	local -r level="$1"
	local -r message="$2"

	local -r context="${3:-${FUNCNAME[1]}}"
	local -r timestamp="$(date +"%Y-%m-%d %H:%M:%S:%N [%Z %:z]")"

	case "$level" in
	INFO | info)
		echo "[$timestamp] [INFO - ${context}] $message"
		;;
	WARN | warn)
		echo "[$timestamp] [WARN - ${context}] $message"
		;;
	DEBUG | debug)
		echo "[$timestamp] [DEBUG - ${context}] $message"
		;;
	ERROR | error)
		echo "[$timestamp] [ERROR - ${context}] $message" >&2
		;;
	*)
		echo "[$timestamp] [UNKNOWN - ${context}] $message"
		;;
	esac
}

function log_kill() {
	local -r message="$1"
	local -ri code="$2"

	local -r context="${3:-${FUNCNAME[1]}}"
	local -r timestamp="$(date +"%Y-%m-%d %H:%M:%S:%N [%Z %:z]")"

	echo "[$timestamp] [KILL - ${context}] $message"
	echo "Exit with code $code"
	exit $code
}
