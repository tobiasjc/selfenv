#!/usr/bin/env bash

source "scripts/lib/os.bash"
source "scripts/lib/pkg_manager.bash"

declare -r FLAMESHOT_PACKAGE_NAME="flameshot"

function script_program_install() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | void | alpine | debian | ubuntu | fedora)
		pkg_manager_install "$FLAMESHOT_PACKAGE_NAME"
		;;
	rhel) ;;
	esac
}

function script_program_uninstall() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | void | alpine | debian | ubuntu | rhel | fedora)
		pkg_manager_uninstall "$FLAMESHOT_PACKAGE_NAME"
		;;
	esac
}

source "scripts/ext/program_menu.bash"
