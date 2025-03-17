#!/usr/bin/env bash

source "scripts/lib/os.bash"
source "scripts/lib/git.bash"
source "scripts/lib/http.bash"
source "scripts/lib/pkg_manager.bash"

declare -r LNAV_EXECUTABLE_NAME="lnav"
declare -r LNAV_EXECUTABLE_INSTALL_DIR="/usr/bin"
declare -r LNAV_EXECUTABLE_FILEPATH="${LNAV_EXECUTABLE_INSTALL_DIR}/${LNAV_EXECUTABLE_NAME}"

declare -r LNAV_MANUAL_NAME="lnav.1"
declare -r LNAV_MANUAL_INSTALL_DIRPATH="/usr/share/man/man1"
declare -r LNAV_MANUAL_FILEPATH="${LNAV_MANUAL_INSTALL_DIRPATH}/${LNAV_MANUAL_NAME}"

declare -r LNAV_REPOSITORY_URL="https://github.com/tstack/lnav"
declare -r LNAV_RAW_DOWNLOAD_ULR="https://github.com/tstack/lnav/releases/download/@{{version_tag}}/lnav-@{{version_number}}-@{{kernel_name}}-musl-@{{architecture}}.zip"

function script_program_install() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | alpine | void)
		pkg_manager_install "${LNAV_EXECUTABLE_NAME}"
		;;
	debian | ubuntu | rhel | fedora)
		local -r version_tag="$(git_echo_latest_tag "$LNAV_REPOSITORY_URL" "^v[0-9]+\.[0-9]+\.[0-9]+$")"
		local -r kernel_name="$(os_echo_kernel_name)"
		local -r architecture="$(os_echo_machine_architecture)"
		local -r download_url="$(echo "$LNAV_RAW_DOWNLOAD_ULR" |
			sed -e "s/@{{version_tag}}/$version_tag/g" |
			sed -e "s/@{{version_number}}/${version_tag/v/}/g" |
			sed -e "s/@{{kernel_name}}/$kernel_name/g" |
			sed -e "s/@{{architecture}}/$architecture/g")"

		local -r download_dirpath="/tmp/lnav"
		local -r download_filename="lnav.zip"
		http_download "$download_url" "$download_dirpath" "$download_filename"

		local -r download_filepath="${download_dirpath}/${download_filename}"
		(unzip -j "$download_filepath" -d "$download_dirpath" "*/${LNAV_EXECUTABLE_NAME}" "*/${LNAV_MANUAL_NAME}" &&
			sudo install --verbose "${download_dirpath}/${LNAV_EXECUTABLE_NAME}" "$LNAV_EXECUTABLE_INSTALL_DIR" &&
			sudo install --verbose "${download_dirpath}/${LNAV_MANUAL_NAME}" "$LNAV_MANUAL_INSTALL_DIRPATH") || exit $?

		sudo rm --verbose --recursive --force "$download_dirpath"
		;;
	esac
}

function script_program_uninstall() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | alpine | void)
		pkg_manager_uninstall "${LNAV_EXECUTABLE_NAME}"
		;;
	debian | ubuntu | rhel | fedora)
		(sudo rm --verbose --recursive --force "$LNAV_EXECUTABLE_FILEPATH" &&
			sudo rm --verbose --recursive --force "$LNAV_MANUAL_FILEPATH") || exit $?
		;;
	esac
}

source "scripts/ext/program_menu.bash"
