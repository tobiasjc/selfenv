#!/usr/bin/env bash

declare ___FILE_ENV_RESOURCES_DIRPATH="resources"

declare ___FILE_CONFIG_DIRPATH="${HOME}/.config"
declare ___FILE_BASH_D_DIRPATH="${HOME}/.bashrc.d"

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
		echo "ERROR ~ [${FUNCNAME[0]}] ~ File at ${target_dir} already exists, and force deletion is false!"
		exit 1
	fi

	rm --verbose --recursive --force "$target_dir" || exit $?
}

function ___file_install() {
	local -r from="$1"
	local -r to="$2"

	(cp --verbose --recursive --force "$from" "$to") || exit $?
}

function file_application_local_install() {
	local -r name="$1"
	local -r string="$2"

	(file_write "${___FILE_LOCAL_APPLICATION_DIRPATH}/${name}" "$string" &&
		sudo update-desktop-database) || exit $?
}

function file_application_local_uninstall() {
	local -r name="$1"

	(rm --verbose --recursive --force "${___FILE_LOCAL_APPLICATION_DIRPATH:?}/${name}" &&
		sudo update-desktop-database) || exit $?
}

function file_application_global_install() {
	local -r name="$1"
	local -r string="$2"

	(file_write "${___FILE_GLOBAL_APPLICATION_DIRPATH}/${name}" "$string" "true" "true" &&
		sudo update-desktop-database) || exit $?
}

function file_application_global_uninstall() {
	local -r name="$1"

	(sudo rm --verbose --recursive --force "${___FILE_LOCAL_APPLICATION_DIRPATH:?}/${name}" &&
		sudo update-desktop-database) || exit $?
}

function file_config_resource_install() {
	local -r name="$1"
	local -r to="${2:-${name}}"

	(mkdir --parents "${___FILE_CONFIG_DIRPATH}" &&
		cp --verbose --recursive --force "${___FILE_ENV_RESOURCES_DIRPATH}/${name}" "${___FILE_CONFIG_DIRPATH}/${to}") || exit $?
}

function file_config_resource_uninstall() {
	local -r name="$1"
	(rm --verbose --recursive --force "${___FILE_CONFIG_DIRPATH:?}/${name}") || exit $?
}

function file_bashrc_d_resource_install() {
	local -r name="$1"
	local -r to="${2:-${name}}"

	(mkdir --parents "${___FILE_BASH_D_DIRPATH}" &&
		cp --verbose --recursive --force "${___FILE_ENV_RESOURCES_DIRPATH}/${name}" "${___FILE_BASH_D_DIRPATH}/${to}") || exit $?
}

function file_bashrc_d_resource_uninstall() {
	local -r name="$1"
	(rm --verbose --recursive --force "${___FILE_BASH_D_DIRPATH:?}/${name}") || exit $?
}
