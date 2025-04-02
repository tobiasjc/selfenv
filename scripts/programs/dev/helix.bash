#!/usr/bin/env bash

source "scripts/lib/git.bash"
source "scripts/lib/http.bash"
source "scripts/lib/os.bash"
source "scripts/lib/installer.bash"
source "scripts/lib/pkg_manager.bash"

declare -r HELIX_BIN_NAME="hx"
declare -r HELIX_CONFIG_NAME="helix"
declare -r HELIX_COMPLETION_NAME="hx.bash"
declare -r HELIX_PKG_NAME_BY_OS_ID=(
	["arch"]="helix"
	["void"]="helix"
	["alpine"]="helix"
	["fedora"]="helix"
)

function script_program_install() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | void | alpine | fedora)
		local -r pkg_name="${HELIX_PKG_NAME_BY_OS_ID[$os_id]}"
		pkg_manager_install "$pkg_name"
		;;
	debian | ubuntu)
		# 1. prepare download
		local -r repository_url="https://github.com/helix-editor/helix"
		local -r version_tag="$(git_echo_latest_tag "$repository_url" '--sort=version:refname' '^[0-9]+\.[0-9]+(\.[0-9]+)?')"
		local -r machine_architecture="$(os_echo_machine_architecture)"
		local -r kernel_name="$(os_echo_kernel_name)"

		# 2. download
		local -r download_dirpath="/tmp/helix"

		local -r download_url="${repository_url}/releases/download/${version_tag}/helix-${version_tag}-${machine_architecture}-${kernel_name}.tar.xz"
		local -r download_filename="helix.tar.xz"
		local -r download_filepath="${download_dirpath}/${download_filename}"
		http_download "$download_url" "$download_dirpath" "$download_filename"

		# 3. install
		tar --verbose --strip-components=1 --extract --directory="$download_dirpath" --file="$download_filepath"
		local -r bin_filepath="${download_dirpath}/${HELIX_BIN_NAME}"
		installer_install_bin_global "$bin_filepath"

		local -r completion_filepath="${download_dirpath}/contrib/completion/${HELIX_COMPLETION_NAME}"
		installer_install_completion "$completion_filepath"

		local -r runtime_dirpath="${download_dirpath}/runtime"
		installer_install_config "$runtime_dirpath" "${HELIX_CONFIG_NAME}"

		# 4. clear
		rm --verbose --recursive --force "$download_dirpath" || exit $?
		;;
	esac
}

function script_program_uninstall() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | void | alpine | fedora)
		local -r pkg_name="${HELIX_PKG_NAME_BY_OS_ID[$os_id]}"
		pkg_manager_uninstall "$pkg_name"
		;;
	debian | ubuntu)
		installer_uninstall_bin_global "$HELIX_BIN_NAME"
		installer_uninstall_completion "$HELIX_COMPLETION_NAME"
		installer_uninstall_config "$HELIX_CONFIG_NAME"
		;;
	esac
}

source "scripts/ext/program_menu.bash"
