#!/usr/bin/env bash

source "scripts/lib/pkg_manager.bash"
source "scripts/lib/http.bash"
source "scripts/lib/os.bash"

declare -r GOOGLE_CHROME_PROGRAM_NAME="google-chrome"
declare -rA GOOGLE_CHROME_PACKAGE_NAME_BY_OS_ID=(
	["arch"]="google-chrome"
	["debian"]="google-chrome-stable"
	["ubuntu"]="google-chrome-stable"
	["fedora"]="google-chrome-stable"
)

declare -rA GOOGLE_CHROME_REPOSITORY_FILENAME_BY_OS_ID=(
	["debian"]="google-chrome.list"
	["ubuntu"]="google-chrome.list"
	["fedora"]="google-chrome.repo"
)

declare -rA GOOGLE_CHROME_SIGNING_KEY_FILENAME_BY_OS_ID=(
	["debian"]="google.asc"
	["ubuntu"]="google.asc"
)

function script_program_install() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch)
		pkg_manager_install "${GOOGLE_CHROME_PACKAGE_NAME_BY_OS_ID[$os_id]}"
		;;
	debian | ubuntu)
		local -r signing_key_url="https://dl.google.com/linux/linux_signing_key.pub"
		local -r signing_key_filename="${GOOGLE_CHROME_SIGNING_KEY_FILENAME_BY_OS_ID[$os_id]}"
		pkg_manager_download_add_signing_key "$signing_key_url" "$signing_key_filename"

		local -r repository_url="http://dl.google.com/linux/chrome/deb/"
		local -r repository_filename="${GOOGLE_CHROME_REPOSITORY_FILENAME_BY_OS_ID[$os_id]}"
		local -r flags="stable main"
		pkg_manager_add_repo "$GOOGLE_CHROME_PROGRAM_NAME" "$repository_filename" "$repository_url" "$signing_key_filename" "$flags"
		pkg_manager_install "${GOOGLE_CHROME_PACKAGE_NAME_BY_OS_ID[$os_id]}"
		;;
	fedora)
		local -r machine_architecture="$(os_echo_machine_architecture)"
		local -r repository_url="http://dl.google.com/linux/chrome/rpm/stable/${machine_architecture}"

		local -r signing_key_url="https://dl.google.com/linux/linux_signing_key.pub"
		local -r repository_filename="${GOOGLE_CHROME_REPOSITORY_FILENAME_BY_OS_ID[$os_id]}"
		pkg_manager_add_repo "$GOOGLE_CHROME_PROGRAM_NAME" "$repository_filename" "$repository_url" "$signing_key_url"
		pkg_manager_install "${GOOGLE_CHROME_PACKAGE_NAME_BY_OS_ID[$os_id]}"
		;;
	esac
}

function script_program_uninstall() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | debian | ubuntu | fedora)
		pkg_manager_uninstall "${GOOGLE_CHROME_PACKAGE_NAME_BY_OS_ID[$os_id]}"

		case "$os_id" in
		debian | ubuntu | fedora)
			pkg_manager_remove_repo "${GOOGLE_CHROME_REPOSITORY_FILENAME_BY_OS_ID[$os_id]}"

			case "$os_id" in
			debian | ubuntu)
				pkg_manager_remove_signing_key "${GOOGLE_CHROME_SIGNING_KEY_FILENAME_BY_OS_ID[$os_id]}"
				;;
			esac
			;;
		esac
		;;
	esac
}

source "scripts/ext/program_menu.bash"
