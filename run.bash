#!/usr/bin/env bash

source "scripts/lib/os.bash"
source "scripts/lib/git.bash"

declare -r RUN_PROGRAMS_DIRPATH="scripts/programs"
declare -r RUN_SYSTEM_DIRPATH="scripts/system"

function list() {
	if [ ${#RUN_GROUPS[@]} -eq 0 ]; then
		for group_dirpath in "$RUN_PROGRAMS_DIRPATH"/*; do
			local group="$(basename "$group_dirpath")"
			echo -e "-> [$group]"
			for program_filepath in "$group_dirpath"/*; do
				local program_name="$(basename "${program_filepath%.*}")"
				echo -e "\t- $program_name"
			done
		done
		return 0
	fi

	for group in "${RUN_GROUPS[@]}"; do
		echo -e "-> [$group]"
		for program_filepath in "${RUN_PROGRAMS_DIRPATH}/${group}"/*; do
			echo -e "\t- $(basename "${program_filepath%.*}")"
		done
	done
}

function run_load_group_programs_filepath() {
	local -n ___ref_programs="$1"
	local -r group="$2"

	local group_dirpath="${RUN_PROGRAMS_DIRPATH}/${group}"
	for program_filepath in "${group_dirpath}"/*; do
		___ref_programs+=("$program_filepath")
	done
}

function run_load_groups_dirpaths() {
	local -n ___ref_groups="$1"
	for group in "$RUN_PROGRAMS_DIRPATH"/*; do
		___ref_groups+=("$group")
	done
}

function run() {
	local -r command="$1"
	if [ "$command" != "install" ] && [ "$command" != "uninstall" ]; then
		return 0
	fi

	local -r os_id="$(os_echo_id)"
	local -r system_filepath="${RUN_SYSTEM_DIRPATH}/${os_id}.bash"
	if [ -e "$system_filepath" ]; then
		source "$system_filepath"
	fi

	for group in "${RUN_GROUPS[@]}"; do
		run_load_group_programs_filepath "programs_filepath" "${group}"
		for program_filepath in "${programs_filepath[@]}"; do
			eval "$program_filepath --${command}"

			local installed_program_name="$(basename "${program_filepath%.*}")"
			for ((i = 0; i < ${#RUN_PROGRAMS[@]}; i++)); do
				if [ "${RUN_PROGRAMS[$i]}" = "$installed_program_name" ]; then
					unset 'RUN_PROGRAMS[$i]'
				fi
			done
		done
		unset programs
	done

	run_load_groups_dirpaths "groups_dirpaths"
	for run_program in "${RUN_PROGRAMS[@]}"; do
		for group_dirpath in "${groups_dirpaths[@]}"; do
			local script_filepath="${group_dirpath}/${run_program}.bash"
			if [ -e "$script_filepath" ]; then
				eval "$script_filepath --${command}"
				break
			fi
		done
	done
}

PARAMS=$(getopt -o "liug:p:" --long "list,install,uninstall,group:,program:" -n "run.bash" -- "$@")
eval set -- "$PARAMS"

declare -a RUN_GROUPS=()
declare -a RUN_PROGRAMS=()
declare cmd=""
while true; do
	case "$1" in
	-l | --list)
		cmd="list"
		shift 1
		;;
	-g | --group)
		RUN_GROUPS+=("$2")
		shift 2
		;;
	-p | --program)
		RUN_PROGRAMS+=("$2")
		shift 2
		;;
	-i | --install)
		if [ -n "$cmd" ]; then
			exit 1
		fi
		cmd="run install"
		shift 1
		;;
	-u | --uninstall)
		if [ -n "$cmd" ]; then
			exit 1
		fi
		cmd="run uninstall"
		shift 1
		;;
	*)
		break
		;;
	esac
done

eval "$cmd"
