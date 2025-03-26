#!/usr/bin/env bash

source "scripts/lib/log.bash"

declare ___FILE_ENV_RESOURCES_DIRPATH="resources"

declare ___FILE_CONFIG_DIRPATH="${HOME}/.config"
declare ___FILE_BASH_D_DIRPATH="${HOME}/.bashrc.d"

declare ___FILE_GLOBAL_MAN_DIRPATH="/usr/share/man/man1"
declare ___FILE_GLOBAL_INSTALL_DIRPATH="/usr/bin"
declare ___FILE_GLOBAL_BASH_COMPLETION_D_DIRPATH="/etc/bash_completion.d"

declare ___FILE_LOCAL_APPLICATION_DIRPATH="${HOME}/.local/share/applications"
declare ___FILE_GLOBAL_APPLICATION_DIRPATH="/usr/share/applications"

function file_write() {
	local -r filepath="$1"
	local -r string="$2"
	local -r overwrite="${3:-true}"
	local -r sudo="${4:-false}"

	if [ -e "$filepath" ] && [ "$overwrite" = "false" ]; then
		return 0
	fi

	if [ ! -d "$(dirname "$filepath")" ]; then
		mkdir --parents --verbose "$(dirname "$filepath")"
	fi

	cmd="tee -p $filepath"
	if [ "$sudo" = "true" ]; then
		cmd="sudo $cmd"
	fi
	cmd="echo -e \"${string}\" | $cmd"
	(eval "$cmd") || exit $?
}

function file_append() {
	local -r filepath="$1"
	local -r string="$2"
	local -r unique="${3:-true}"
	local -r sudo="${4:-false}"

	cmd="tee -p --append $filepath"
	if [ "$sudo" = "true" ]; then
		cmd="sudo $cmd"
	fi
	cmd="echo -e \"${string}\" | $cmd"

	if [ ! -e "$filepath" ]; then
		local mkdir_cmd=""
		if [ "$sudo" = "true" ]; then
			mkdir_cmd="sudo"
		fi
		mkdir_cmd=" mkdir --parents $(dirname "$filepath")"

		(eval "$mkdir_cmd") || exit $?
		(eval "$cmd") || exit $?
		return 0
	fi

	if [ "$unique" != "true" ]; then
		(eval "$cmd") || exit $?
		return 0
	fi

	local -r file_long_string="$(cat "$filepath" | tr -d '[:cntrl:]')"
	local -r long_string="$(echo "$string" | tr -d '[:cntrl:]')"
	if [[ $file_long_string =~ $long_string ]]; then
		return 0
	fi

	(eval "$cmd") || exit $?
}

function file_verify_not_exists() {
	local -r target_dir="$1"
	local -r force="${2:-false}"

	if [ ! -e "$target_dir" ]; then
		return 0
	fi

	if [ "$force" != "true" ]; then
		log_kill "File at ${target_dir} already exists, and force deletion is false!"
	fi

	(rm --verbose --recursive --force "$target_dir") || exit $?
}
