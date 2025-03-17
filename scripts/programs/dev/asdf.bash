#!/usr/bin/env bash

source "scripts/lib/git.bash"
source "scripts/lib/http.bash"
source "scripts/lib/file.bash"
source "scripts/lib/pkg_manager.bash"
source "scripts/lib/md5.bash"

declare -r ASDF_PROGRAM_NAME="asdf"
declare -r ASDF_INSTALL_DIRPATH="/usr/bin"
declare -r ASDF_EXECUTABLE_FILEPATH="${ASDF_INSTALL_DIRPATH}/${ASDF_PROGRAM_NAME}"

declare -r ASDF_REPOSITORY_URL="https://github.com/asdf-vm/asdf"
declare -r ASDF_RAW_DOWNLOAD_URL="https://github.com/asdf-vm/asdf/releases/download/@{{tag}}/asdf-@{{tag}}-@{{kernel_name}}-@{{machine_architecture}}.tar.gz"

declare -r ASDF_DOWNLOAD_DIRPATH="/tmp/asdf"

declare -r ASDF_DOWNLOAD_FILENAME="asdf.tar.gz"
declare -r ASDF_DOWNLOAD_FILEPATH="${ASDF_DOWNLOAD_DIRPATH}/${ASDF_DOWNLOAD_FILENAME}"
declare -r ASDF_MD5_DOWNLOAD_FILENAME="asdf.tar.gz.md5"
declare -r ASDF_MD5_DOWNLOAD_FILEPATH="${ASDF_DOWNLOAD_DIRPATH}/${ASDF_MD5_DOWNLOAD_FILENAME}"

declare -r ASDF_BASH_COMPLETION_DIRPATH="/etc/bash_completion.d"
declare -r ASDF_BASH_COMPLETION_FILENAME="asdf.bash"
declare -r ASDF_BASH_COMPLETION_FILEPATH="${ASDF_BASH_COMPLETION_DIRPATH}/${ASDF_BASH_COMPLETION_FILENAME}"

declare -r ASDF_BASHRC_D_RESOURCE_NAME="asdf.bash"

function script_program_install() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch)
		(pkg_manager_install "asdf-vm" &&
			pkg_manager_install "bash-completion" &&
			asdf_install_env) || exit $?
		;;
	alpine | void | debian | ubuntu | rhel | fedora)
		local -r tag="$(git_echo_latest_tag "$ASDF_REPOSITORY_URL")"
		local -r machine_architecture="$(os_echo_machine_architecture)"
		local -r machine_architecture_amd="$(os_echo_architecture_to_amd "$machine_architecture")"
		local -r kernel_name="$(os_echo_kernel_name)"
		local -r asdf_download_url="$(echo "$ASDF_RAW_DOWNLOAD_URL" |
			sed -e "s/@{{tag}}/$tag/g" |
			sed -e "s/@{{kernel_name}}/$kernel_name/g" |
			sed -e "s/@{{machine_architecture}}/$machine_architecture_amd/g")"
		local -r asdf_md5_checksum_download_url="${asdf_download_url}.md5"

		(http_download "$asdf_download_url" "$ASDF_DOWNLOAD_DIRPATH" "$ASDF_DOWNLOAD_FILENAME" &&
			http_download "$asdf_md5_checksum_download_url" "$ASDF_DOWNLOAD_DIRPATH" "$ASDF_MD5_DOWNLOAD_FILENAME" &&
			md5_check_hash_file "$ASDF_DOWNLOAD_FILEPATH" "$ASDF_MD5_DOWNLOAD_FILEPATH") || exit $?

		(tar --verbose --extract --directory="$ASDF_DOWNLOAD_DIRPATH" --file="$ASDF_DOWNLOAD_FILEPATH" &&
			sudo install --verbose "${ASDF_DOWNLOAD_DIRPATH}/${ASDF_PROGRAM_NAME}" "$ASDF_INSTALL_DIRPATH" &&
			rm --recursive --force "$ASDF_DOWNLOAD_DIRPATH" &&
			asdf_install_env) || exit $?
		;;
	esac
}

function script_program_uninstall() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch)
		(pkg_manager_uninstall "asdf-vm" &&
			asdf_uninstall_env) || exit $?
		;;
	alpine | void | debian | ubuntu | rhel | fedora)
		(sudo rm --verbose --recursive --force "$ASDF_EXECUTABLE_FILEPATH" &&
			asdf_uninstall_env) || exit $?
		;;
	esac
}

function asdf_install_env() {
	(file_bashrc_d_resource_install "$ASDF_BASHRC_D_RESOURCE_NAME" &&
		asdf completion bash | sudo tee "$ASDF_BASH_COMPLETION_FILEPATH") || exit $?
}

function asdf_uninstall_env() {
	(file_bashrc_d_resource_uninstall "$ASDF_BASHRC_D_RESOURCE_NAME" &&
		sudo rm --verbose --recursive --force "$ASDF_BASH_COMPLETION_FILEPATH") || exit $?
}

source "scripts/ext/program_menu.bash"
