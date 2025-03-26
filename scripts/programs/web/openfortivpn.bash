#!/usr/bin/env bash

source "scripts/lib/git.bash"
source "scripts/lib/os.bash"
source "scripts/lib/pkg_manager.bash"

declare -ra OPENFORTIVPN_PKG_BY_OS_ID=(
	["arch"]="openfortivpn"
	["void"]="openfortivpn"
	["alpine"]="openfortivpn"
	["debian"]="openfortivpn"
	["ubuntu"]="openfortivpn"
	["fedora"]="openfortivpn"
)

function script_program_install() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | void | alpine | debian | ubuntu | fedora)
		pkg_manager_install "${OPENFORTIVPN_PKG_BY_OS_ID[$os_id]}"
		;;
	esac
}

source "scripts/ext/program_menu.bash"
