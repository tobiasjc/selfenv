#!/usr/bin/env bash

source "scripts/lib/git.bash"
source "scripts/lib/http.bash"
source "scripts/lib/os.bash"
source "scripts/lib/installer.bash"

declare -r JETBRAINS_TOOLBOX_BIN_NAME="jetbrains-toolbox"

function script_program_install() {
	local -r os_id="$(os_echo_id)"

	case "$os_id" in
	arch | void | alpine | debian | ubuntu | fedora)
		local -r download_dirpath="/tmp/jetbrains-toolbox"

		# 1. versioning
		local -r version_file_filename="jetbrains-toolbox-versions.json"
		local -r version_url="https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release"
		http_download "$version_url" "$download_dirpath" "$version_file_filename"

		./run.bash --program jq --install
		local -r version_file_filepath="${download_dirpath}/${version_file_filename}"
		local -r kernel_name="$(os_echo_kernel_name)"
		local -r download_url="$(jq --raw-output ".TBA[0].downloads.${kernel_name}.link" "$version_file_filepath")"

		# 2. download
		local -r download_filename="$(basename "$download_url")"
		http_download "$download_url" "$download_dirpath" "$download_filename"
		local -r download_filepath="${download_dirpath}/${download_filename}"
		tar --verbose --extract --strip-components=1 --directory="$download_dirpath" --file="$download_filepath"

		# 3. install
		local -r bin_filepath="${download_dirpath}/${JETBRAINS_TOOLBOX_BIN_NAME}"
		installer_install_bin_local "$bin_filepath"

		# 4. clear
		rm --verbose --recursive --force "$download_dirpath"
		;;
	esac
}

function script_program_uninstall() {
	local -r os_id="$(os_echo_id)"

	case "$os_id" in
	arch | void | alpine | debian | ubuntu | fedora)
		installer_uninstall_bin_local "$JETBRAINS_TOOLBOX_BIN_NAME"
		;;
	esac
}

source "scripts/ext/program_menu.bash"
