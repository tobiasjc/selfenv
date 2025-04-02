#!/usr/bin/env bash

source "scripts/lib/git.bash"
source "scripts/lib/http.bash"
source "scripts/lib/pkg_manager.bash"
source "scripts/lib/checksum.bash"
source "scripts/lib/installer.bash"

declare -r ASDF_BIN_NAME="asdf"

declare -r ASDF_BASHRC_D_RESOURCE_NAME="asdf.bash"
declare -r ASDF_BASHRC_COMPLETION_NAME="asdf.bash"

declare -ra ASDF_PKG_NAME_BY_OS_ID=(
	["arch"]="asdf-vm"
	["alpine"]="asdf-vm"
)

function script_program_install() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | alpine)
		(pkg_manager_install "${ASDF_PKG_NAME_BY_OS_ID[$os_id]}" &&
			asdf_install_env) || exit $?
		;;
	void | debian | ubuntu | fedora)
		# 1. versioning
		local -r repository_url="https://github.com/asdf-vm/asdf"
		local -r version_tag="$(git_echo_latest_tag "$repository_url" '--sort=version:refname' '^v[0-9]+\.[0-9]+\.[0-9]+$')"
		local -r machine_architecture="$(os_echo_machine_architecture)"
		local -r machine_architecture_amd="$(os_echo_architecture_to_amd "$machine_architecture")"
		local -r kernel_name="$(os_echo_kernel_name)"

		# 2. download
		local -r download_dirpath="/tmp/asdf"

		local -r download_url="https://github.com/asdf-vm/asdf/releases/download/${version_tag}/asdf-${version_tag}-${kernel_name}-${machine_architecture_amd}.tar.gz"
		local -r download_filename="asdf.tar.gz"
		http_download "$download_url" "$download_dirpath" "$download_filename"

		local -r asdf_md5_checksum_download_url="${download_url}.md5"
		local -r md5_download_filename="asdf.tar.gz.md5"
		http_download "$asdf_md5_checksum_download_url" "$download_dirpath" "$md5_download_filename"

		local -r md5_download_filepath="${download_dirpath}/${md5_download_filename}"
		local -r download_filepath="${download_dirpath}/${download_filename}"
		checksum_md5_file "$download_filepath" "$md5_download_filepath"

		# 3. install
		tar --verbose --extract --directory="$download_dirpath" --file="$download_filepath" || exit $?
		installer_install_bin_global "${download_dirpath}/${ASDF_BIN_NAME}"
		installer_install_bashrc_d_resource "$ASDF_BASHRC_D_RESOURCE_NAME"
		installer_install_command_completion "$ASDF_BASHRC_COMPLETION_NAME" "asdf completion bash"
		asdf_install_env

		# 4. clean
		rm --verbose --recursive --force "$download_dirpath" || exit $?
		;;
	esac
}

function script_program_uninstall() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch)
		pkg_manager_uninstall "${ASDF_PKG_NAME_BY_OS_ID[$os_id]}"
		asdf_uninstall_env
		;;
	alpine | void | debian | ubuntu | fedora)
		installer_uninstall_bin_global "$ASDF_BIN_NAME"
		asdf_uninstall_env
		;;
	esac
}

function asdf_install_env() {
	installer_install_bashrc_d_resource "$ASDF_BASHRC_D_RESOURCE_NAME"
	installer_install_command_completion "$ASDF_BASHRC_COMPLETION_NAME" "asdf completion bash"
}

function asdf_uninstall_env() {
	installer_uninstall_bashrc_d "$ASDF_BASHRC_D_RESOURCE_NAME"
	installer_uninstall_completion "$ASDF_BASHRC_COMPLETION_NAME"
}

source "scripts/ext/program_menu.bash"
