#!/usr/bin/env bash

source "scripts/lib/git.bash"
source "scripts/lib/http.bash"
source "scripts/lib/os.bash"

declare -r LAZYGIT_PROGRAM_NAME="lazygit"
declare -r LAZYGIT_EXECUTABLE_PATH="/usr/bin/${LAZYGIT_PROGRAM_NAME}"
declare -r LAZYGIT_REPOSITORY_URL="https://github.com/jesseduffield/lazygit"
declare -r LAZYGIT_RESOURCE_DOWNLOAD_URL="https://github.com/jesseduffield/lazygit/releases/download/@{{version_tag}}/lazygit_@{{version}}_@{{kernel}}_@{{architecture}}.tar.gz"

function script_program_install() {
	local version="${1:-latest}"
	local version_tag="v${version}"

	# 1. get version
	if [ "$version" = "latest" ]; then
		version_tag="$(git_echo_latest_tag "$LAZYGIT_REPOSITORY_URL")"
		version="${version_tag/v/}"
	fi

	# 2. build resources download url
	local -r kernel_name="$(os_echo_kernel_name)"
	local -r machine_architecture="$(os_echo_machine_architecture)"
	local -r url="$(echo "$LAZYGIT_RESOURCE_DOWNLOAD_URL" |
		sed -e "s/@{{version_tag}}/$version_tag/g" |
		sed -e "s/@{{version}}/$version/g" |
		sed -e "s/@{{kernel}}/${kernel_name^}/g" |
		sed -e "s/@{{architecture}}/$machine_architecture/g")" || exit $?

	echo "url = $url"

	# 3. download
	output_dir="/tmp"
	download_filename="${LAZYGIT_PROGRAM_NAME}.tar.gz"
	http_download "$url" "$output_dir" "$download_filename"

	# 4. install
	archive_path="${output_dir}/${download_filename}"
	(tar --verbose --extract --file="${archive_path}" --directory="$output_dir" --overwrite "${LAZYGIT_PROGRAM_NAME}" &&
		sudo mv "${output_dir}/${LAZYGIT_PROGRAM_NAME}" "${LAZYGIT_EXECUTABLE_PATH}" &&
		sudo rm --verbose --recursive --force "${archive_path}") || exit $?
}

function script_program_uninstall() {
	sudo rm --verbose --recursive --force "${LAZYGIT_EXECUTABLE_PATH}" || exit $?
}

source "scripts/ext/program_menu.bash"
