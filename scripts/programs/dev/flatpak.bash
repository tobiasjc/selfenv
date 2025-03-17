#!/usr/bin/env bash

source "scripts/lib/pkg_manager.bash"
source "scripts/lib/os.bash"

function script_program_install() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | void | alpine | debian | ubuntu | rhel | fedora)
		pkg_manager_install "flatpak"
		eval "flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo" || exit $?
		;;
	esac
}

function script_program_uninstall() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | void | alpine | debian | ubuntu | rhel | fedora)
		pkg_manager_uninstall "flatpak"
		;;
	esac
}

source "scripts/ext/program_menu.bash"
