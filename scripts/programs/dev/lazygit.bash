#!/usr/bin/env bash

source "scripts/lib/git.bash"
source "scripts/lib/http.bash"
source "scripts/lib/os.bash"
source "scripts/lib/installer.bash"

declare -r LAZYGIT_BIN_NAME="lazygit"

function script_program_install() {
	local -r os_id="$(os_echo_id)"

	case "$os_id" in
	arch | void | alpine | debian | ubuntu | fedora)
		# 1. versioning
		local -r repository_url="https://github.com/jesseduffield/lazygit"
		local -r version_tag="$(git_echo_latest_tag "$repository_url" '--sort=version:refname' '^v[0-9]+\.[0-9]+\.[0-9]+$')"
		local -r kernel_name="$(os_echo_kernel_name)"
		local -r machine_architecture="$(os_echo_machine_architecture)"

		# 3. download
		local -r output_dir="/tmp/lazygit"

		local -r download_url="${repository_url}/releases/download/${version_tag}/lazygit_${version_tag/v/}_${kernel_name}_${machine_architecture}.tar.gz"
		local -r download_filename="${LAZYGIT_BIN_NAME}.tar.gz"
		http_download "$download_url" "$output_dir" "$download_filename"

		# 4. install
		archive_path="${output_dir}/${download_filename}"
		tar --verbose --extract --file="${archive_path}" --directory="$output_dir" --overwrite "${LAZYGIT_BIN_NAME}" || exit $?
		installer_install_bin_global "${output_dir}/${LAZYGIT_BIN_NAME}"

		# 5. clear
		rm --verbose --recursive --force "$output_dir" || exit $?
		;;
	esac
}

function script_program_uninstall() {
	local -r os_id="$(os_echo_id)"

	case "$os_id" in
	arch | void | alpine | debian | ubuntu | fedora)
		installer_uninstall_bin_global "$LAZYGIT_BIN_NAME"
		;;
	esac
}

source "scripts/ext/program_menu.bash"
