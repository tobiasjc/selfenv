#!/usr/bin/env bash

source "scripts/lib/os.bash"
source "scripts/lib/pkg_manager.bash"

declare -r DOOM_EMACS_EMACS_PACKAGE_NAME="emacs"
declare -ra DOOM_EMACS_DEPENDENCIES=("ripgrep")

function script_program_install() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | void | alpine | debian | ubuntu | rhel | fedora)
		pkg_manager_install "$EMACS_PACKAGE_NAME"
		;;
	esac
}

function script_program_uninstall() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | void | alpine | debian | ubuntu | rhel | fedora)
		pkg_manager_uninstall "$EMACS_PACKAGE_NAME"
		;;
	esac
}

source "scripts/ext/program_menu.bash"
