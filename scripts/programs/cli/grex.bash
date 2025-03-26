#!/usr/bin/env bash

source "scripts/lib/git.bash"
source "scripts/lib/os.bash"
source "scripts/lib/http.bash"
source "scripts/lib/pkg_manager.bash"

declare -r GREX_EXECUTABLE_NAME="grex"
declare -r GREX_EXECUTABLE_INSTALL_DIRPATH="/usr/bin"
declare -r GREX_EXECUTABLE_FILEPATH="${GREX_EXECUTABLE_INSTALL_DIRPATH}/${GREX_EXECUTABLE_NAME}"

declare -r GREX_REPOSITORY_URL="https://github.com/pemistahl/grex"

declare -r GREX_RAW_DOWNLOAD_URL="https://github.com/pemistahl/grex/releases/download/@{{version_tag}}/grex-@{{version_tag}}-@{{architecture}}-unknown-@{{kernel_name}}-musl.tar.gz"
declare -r GREX_DOWNLOAD_DIRPATH="/tmp/grex"
declare -r GREX_DOWNLOAD_FILENAME="grex.tar.gz"
declare -r GREX_DOWNLOAD_FILEPATH="${GREX_DOWNLOAD_DIRPATH}/${GREX_DOWNLOAD_FILENAME}"
declare -r GREX_DOWNLOAD_EXECUTABLE_FILEPATH="${GREX_DOWNLOAD_DIRPATH}/${GREX_EXECUTABLE_NAME}"

function script_program_install() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | void | alpine | debian | ubuntu | fedora)
		local -r version_tag="$(git_echo_latest_tag "$GREX_REPOSITORY_URL")"
		local -r architecture="$(os_echo_machine_architecture)"
		local -r kernel_name="$(os_echo_kernel_name)"
		local -r download_url="$(echo "$GREX_RAW_DOWNLOAD_URL" |
			sed -e "s/@{{version_tag}}/$version_tag/g" |
			sed -e "s/@{{architecture}}/$architecture/g" |
			sed -e "s/@{{kernel_name}}/$kernel_name/g")"

		http_download "$download_url" "$GREX_DOWNLOAD_DIRPATH" "$GREX_DOWNLOAD_FILENAME"
		(tar --verbose --extract --directory="$GREX_DOWNLOAD_DIRPATH" --file="$GREX_DOWNLOAD_FILEPATH" &&
			sudo install --verbose ${GREX_DOWNLOAD_EXECUTABLE_FILEPATH} "${GREX_EXECUTABLE_INSTALL_DIRPATH}" &&
			rm --verbose --recursive --force "$GREX_DOWNLOAD_DIRPATH")
		;;
	esac
}

function script_program_uninstall() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | void | alpine | debian | ubuntu | fedora)
		sudo rm --verbose --recursive --force "$GREX_EXECUTABLE_FILEPATH"
		;;
	esac
}

source "scripts/ext/program_menu.bash"
