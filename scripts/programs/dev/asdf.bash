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

declare -r ASDF_REPOSITORY_URL="https://github.com/asdf-vm/asdf"
declare -r ASDF_RAW_DOWNLOAD_URL="https://github.com/asdf-vm/asdf/releases/download/@{{tag}}/asdf-@{{tag}}-@{{kernel_name}}-@{{machine_architecture}}.tar.gz"

function script_program_install() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | alpine)
		(pkg_manager_install "${ASDF_PKG_NAME_BY_OS_ID[$os_id]}" &&
			asdf_install_env) || exit $?
		;;
	void | debian | ubuntu | fedora)
		# 1 download
		local -r tag="$(git_echo_latest_tag "$ASDF_REPOSITORY_URL")"
		local -r machine_architecture="$(os_echo_machine_architecture)"
		local -r machine_architecture_amd="$(os_echo_architecture_to_amd "$machine_architecture")"
		local -r kernel_name="$(os_echo_kernel_name)"
		local -r asdf_download_url="$(echo "$ASDF_RAW_DOWNLOAD_URL" |
			sed -e "s/@{{tag}}/$tag/g" |
			sed -e "s/@{{kernel_name}}/$kernel_name/g" |
			sed -e "s/@{{machine_architecture}}/$machine_architecture_amd/g")"
		local -r asdf_md5_checksum_download_url="${asdf_download_url}.md5"

		local -r download_dirpath="/tmp/asdf"
		local -r download_filename="asdf.tar.gz"
		local -r download_filepath="${download_dirpath}/${download_filename}"

		local -r md5_download_filename="asdf.tar.gz.md5"
		local -r md5_download_filepath="${download_dirpath}/${md5_download_filename}"

		(http_download "$asdf_download_url" "$download_dirpath" "$download_filename" &&
			http_download "$asdf_md5_checksum_download_url" "$download_dirpath" "$md5_download_filename" &&
			checksum_md5_file "$download_filepath" "$md5_download_filepath") || exit $?

		# 2. install
		(
			tar --verbose --extract --directory="$download_dirpath" --file="$download_filepath" &&
				installer_install_global_bin "${download_dirpath}/${ASDF_BIN_NAME}" &&
				installer_install_bashrc_d_resource "$ASDF_BASHRC_D_RESOURCE_NAME"
			installer_install_command_completion "$ASDF_BASHRC_COMPLETION_NAME" "asdf completion bash"
			asdf_install_env
		) || exit $?

		# 3. clean
		(rm --verbose --recursive --force "$download_dirpath") || exit $?
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
		installer_uninstall_global_bin "$ASDF_BIN_NAME"
		asdf_uninstall_env
		;;
	esac
}

function asdf_install_env() {
	installer_install_bashrc_d_resource "$ASDF_BASHRC_D_RESOURCE_NAME"
	installer_install_command_completion "$ASDF_BASHRC_COMPLETION_NAME" "asdf completion bash"
}

function asdf_uninstall_env() {
	installer_uninstall_bashrc_d_resource "$ASDF_BASHRC_D_RESOURCE_NAME"
	installer_uninstall_completion "$ASDF_BASHRC_COMPLETION_NAME"
}

source "scripts/ext/program_menu.bash"
