#!/usr/bin/env bash

source "scripts/lib/git.bash"
source "scripts/lib/os.bash"
source "scripts/lib/http.bash"
source "scripts/lib/installer.bash"
source "scripts/lib/pkg_manager.bash"

declare -r NUSHELL_BIN_NAME="nu"

declare -rA NUSHELL_PKG_NAME_BY_OS_ID=(
	["arch"]="nushell"
	["void"]="nushell"
	["alpine"]="nushell nushell-doc nushell-plugins"
	["fedora"]="nu"
)

function script_program_install() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | void | alpine | fedora)
		local -r pkg="${NUSHELL_PKG_NAME_BY_OS_ID[$os_id]}"
		pkg_manager_install "$pkg"
		;;
	debian | ubuntu)
		# 1. versioning
		local -r repository_url="https://github.com/nushell/nushell"
		local -r version="$(git_echo_latest_tag "$repository_url" '--sort=version:refname' '^[0-9]+\.[0-9]+\.[0-9]+$')"
		local -r machine_architecture="$(os_echo_machine_architecture)"
		local -r kernel_name="$(os_echo_kernel_name)"

		# 2. download
		local -r download_dirpath="/tmp/nu-shell"

		local -r download_url="https://github.com/nushell/nushell/releases/download/${version}/nu-${version}-${machine_architecture}-unknown-${kernel_name}-musl.tar.gz"
		local -r download_filename="nu-shell.tar.gz"
		http_download "$download_url" "$download_dirpath" "$download_filename"

		# 3. prepare install
		local -r download_filepath="${download_dirpath}/${download_filename}"
		tar --extract --directory="$download_dirpath" --strip-components=1 --file="$download_filepath"

		# 4. install
		installer_install_bin_global "${download_dirpath}/${NUSHELL_BIN_NAME}"

		# 5. clear
		sudo rm -rf "$download_dirpath" || exit $?
		;;
	esac
}

function script_program_uninstall() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | void | alpine | fedora)
		local -r pkg="${NUSHELL_PKG_NAME_BY_OS_ID[$os_id]}"
		pkg_manager_uninstall "$pkg"
		;;
	debian | ubuntu)
		installer_uninstall_bin_global "$NUSHELL_BIN_NAME"
		;;
	esac
}

source "scripts/ext/program_menu.bash"
