#!/usr/bin/env bash

source "scripts/lib/os.bash"
source "scripts/lib/git.bash"
source "scripts/lib/http.bash"
source "scripts/lib/pkg_manager.bash"
source "scripts/lib/installer.bash"

declare -rA HTMLQ_PACKAGES_BY_OS_ID=(
	["arch"]="htmlq"
	["alpine"]="htmlq"
)

declare -r HTMLQ_BIN_NAME="htmlq"

function script_program_install() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | alpine)
		pkg_manager_install "${HTMLQ_PACKAGES_BY_OS_ID[$os_id]}"
		;;
	debian | ubuntu | fedora)
		# 1. versioning
		local -r repository_url="https://github.com/mgdm/htmlq"
		local -r version_tag="$(git_echo_latest_tag "$repository_url" '--sort=version:refname' '^v[0-9]+\.[0-9]+\.[0-9]+$')"
		local -r architecture="$(os_echo_machine_architecture)"
		local -r kernel_name="$(os_echo_kernel_name)"

		# 2. download
		local -r download_output_dirpath="/tmp/htmlq"

		local -r download_url="${repository_url}/releases/download/${version_tag}/htmlq-${architecture}-${kernel_name}.tar.gz"
		local -r download_filename="htmlq.tar.gz"
		local -r download_filepath="${download_output_dirpath}/${download_filename}"
		http_download "$download_url" "$download_output_dirpath" "$download_filename"

		# 3. install
		tar --verbose --extract --directory="$download_output_dirpath" --file="$download_filepath" || exit $?
		local -r bin_filepath="${download_output_dirpath}/${HTMLQ_BIN_NAME}"
		installer_install_bin_global "$bin_filepath"

		# 4. clear
		rm --verbose --recursive --force "$download_output_dirpath"
		;;
	esac
}

function script_program_uninstall() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | alpine)
		pkg_manager_uninstall "${HTMLQ_PACKAGES_BY_OS_ID[$os_id]}"
		;;
	debian | ubuntu | fedora)
		installer_uninstall_bin_global "$HTMLQ_BIN_NAME"
		;;
	esac
}

source "scripts/ext/program_menu.bash"
