#!/usr/bin/env bash

PARAMS=$(getopt -o "iuv:" --long "install,uninstall,version:" -n "program_menu.bash" -- "$@")
eval set -- "$PARAMS"

cmd=""
while true; do
	case "$1" in
	-i | --install)
		cmd="script_program_install"
		shift 1
		;;
	-u | --uninstall)
		cmd="script_program_uninstall"
		shift 1
		;;
	-v | --version)
		cmd+=" $2"
		shift 2
		;;
	*)
		break
		;;
	esac
done

eval "$cmd"
