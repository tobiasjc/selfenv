#!/usr/bin/env bash

source "scripts/lib/git.bash"
source "scripts/lib/os.bash"
source "scripts/lib/http.bash"
source "scripts/lib/pkg_manager.bash"
source "scripts/lib/installer.bash"

declare -r GREX_BIN_NAME="grex"

function script_program_install() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | void | alpine | debian | ubuntu | fedora)
		# 1. versioning
		local -r repository_url="https://github.com/pemistahl/grex"
		local -r version_tag="$(git_echo_latest_tag "$repository_url" '--sort=version:refname')"
		local -r architecture="$(os_echo_machine_architecture)"
		local -r kernel_name="$(os_echo_kernel_name)"

		# 2. download
		local -r download_dirpath="/tmp/grex"

		local -r download_url="${repository_url}/releases/download/${version_tag}/grex-${version_tag}-${architecture}-unknown-${kernel_name}-musl.tar.gz"
		local -r download_filename="grex.tar.gz"
		local -r download_filepath="${download_dirpath}/${download_filename}"
		http_download "$download_url" "$download_dirpath" "$download_filename"

		# 3. install
		tar --verbose --extract --directory="$download_dirpath" --file="$download_filepath" || exit $?
		local -r bin_filepath="${download_dirpath}/${GREX_BIN_NAME}"
		installer_install_bin_global "$bin_filepath"

		# 4. clear
		rm --verbose --recursive --force "$GREX_DOWNLOAD_DIRPATH" || exit $?
		;;
	esac
}

function script_program_uninstall() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | void | alpine | debian | ubuntu | fedora)
		installer_uninstall_bin_global "$GREX_BIN_NAME"
		;;
	esac
}

source "scripts/ext/program_menu.bash"
