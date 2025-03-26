#!/bin/bash

function ___log() {
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
	KILL | kill)
		echo "[$timestamp] [KILL - ${context}] $message" >&2
		;;
	*)
		echo "[$timestamp] [UNKNOWN - ${context}] $message"
		;;
	esac
}

function log_info() {
	___log "info" "$1"
}

function log_warn() {
	___log "warn" "$1"
}

function log_debug() {
	___log "debug" "$1"
}

function log_error() {
	___log "error" "$1"
}

function log_kill() {
	___log "kill" "$1"
	exit "${2:-127}"
}
