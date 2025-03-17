#!/usr/bin/env bash

source "scripts/lib/os.bash"
source "scripts/lib/pkg_manager.bash"

declare -r FIREFOX_PACKAGE_NAME="firefox"

declare -rA FIREFOX_REPOSITORY_FILENAME_BY_OS=(
	["debian"]="mozilla-firefox.list"
	["ubuntu"]="mozilla-firefox.list"
)

declare -rA FIREFOX_SIGNING_KEY_FILENAME_BY_OS=(
	["debian"]="packages.mozilla.org.asc"
	["ubuntu"]="packages.mozilla.org.asc"
)

function script_program_install() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | void | alpine | rhel | fedora)
		pkg_manager_install "$FIREFOX_PACKAGE_NAME"
		;;
	debian | ubuntu)
		local -r signing_key_url="https://packages.mozilla.org/apt/repo-signing-key.gpg"
		local -r signing_key_filename="${FIREFOX_SIGNING_KEY_FILENAME_BY_OS[$os_id]}"
		pkg_manager_download_add_signing_key "$signing_key_url" "$signing_key_filename"

		local -r repository_url="https://packages.mozilla.org/apt"
		local -r repository_filename="${FIREFOX_REPOSITORY_FILENAME_BY_OS[$os_id]}"
		local -r flags="mozilla main"
		pkg_manager_add_repo "$FIREFOX_PACKAGE_NAME" "$repository_filename" "$repository_url" "$signing_key_filename" "$flags"
		pkg_manager_install "$FIREFOX_PACKAGE_NAME"
		;;
	esac
}

function script_program_uninstall() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | void | alpine | debian | ubuntu | rhel | fedora)
		pkg_manager_uninstall "$FIREFOX_PACKAGE_NAME"

		case "$os_id" in
		debian | ubuntu)
			pkg_manager_remove_repo "${FIREFOX_REPOSITORY_FILENAME_BY_OS[$os_id]}"
			pkg_manager_remove_signing_key "${FIREFOX_SIGNING_KEY_FILENAME_BY_OS[$os_id]}"
			;;
		esac
		;;
	esac
}

source "scripts/ext/program_menu.bash"
