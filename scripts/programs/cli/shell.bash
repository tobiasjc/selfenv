#!/usr/bin/env bash

source "scripts/lib/git.bash"
source "scripts/lib/os.bash"
source "scripts/lib/http.bash"
source "scripts/lib/file.bash"
source "scripts/lib/pkg_manager.bash"

declare -rA SHELL_PKG_NAME_BY_OS_ID=(
	["arch"]="shellcheck shfmt"
	["void"]="shellcheck shfmt"
	["alpine"]="shellcheck shfmt"
	["debian"]="shellcheck shfmt"
	["ubuntu"]="shellcheck shfmt"
	["fedora"]="ShellCheck shfmt"
)

function script_program_install() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | void | alpine | debian | ubuntu | fedora)
		pkg_manager_install "${SHELL_PKG_NAME_BY_OS_ID[$os_id]}"
		;;
	esac
}

function script_program_uninstall() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | void | alpine | debian | ubuntu | fedora)
		pkg_manager_uninstall "${SHELL_PKG_NAME_BY_OS_ID[$os_id]}"
		;;
	esac
}

source "scripts/ext/program_menu.bash"
