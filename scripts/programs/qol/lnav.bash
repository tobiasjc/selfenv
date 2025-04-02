#!/usr/bin/env bash

source "scripts/lib/os.bash"
source "scripts/lib/git.bash"
source "scripts/lib/http.bash"
source "scripts/lib/installer.bash"
source "scripts/lib/pkg_manager.bash"

declare -r LNAV_BIN_NAME="lnav"
declare -r LNAV_MAN1_NAME="lnav.1"

function script_program_install() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | alpine | void)
		pkg_manager_install "${LNAV_BIN_NAME}"
		;;
	debian | ubuntu | fedora)
		# 1. versioning
		local -r repository_url="https://github.com/tstack/lnav"
		local -r version_tag="$(git_echo_latest_tag "$repository_url" '--sort=version:refname' '^v[0-9]+\.[0-9]+\.[0-9]+$')"
		local -r kernel_name="$(os_echo_kernel_name)"
		local -r architecture="$(os_echo_machine_architecture)"

		# 2. download
		local -r download_dirpath="/tmp/lnav"

		local -r download_url="https://github.com/tstack/lnav/releases/download/${version_tag}/lnav-${version_tag/v/}-${kernel_name}-musl-${architecture}.zip"
		local -r download_filename="lnav.zip"
		http_download "$download_url" "$download_dirpath" "$download_filename"

		# 3. prepare install
		local -r download_filepath="${download_dirpath}/${download_filename}"
		unzip -j "$download_filepath" -d "$download_dirpath" "*/${LNAV_BIN_NAME}" "*/${LNAV_MAN1_NAME}" || exit $?

		# 4. install
		installer_install_bin_global "${download_dirpath}/${LNAV_BIN_NAME}"
		installer_install_man1 "${download_dirpath}/${LNAV_MAN1_NAME}"

		# 5. clear
		sudo rm --verbose --recursive --force "$download_dirpath" || exit $?
		;;
	esac
}

function script_program_uninstall() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | alpine | void)
		pkg_manager_uninstall "${LNAV_BIN_NAME}"
		;;
	debian | ubuntu | fedora)
		installer_uninstall_bin_global "$LNAV_BIN_NAME"
		installer_uninstall_man1 "$LNAV_MAN1_NAME"
		;;
	esac
}

source "scripts/ext/program_menu.bash"
