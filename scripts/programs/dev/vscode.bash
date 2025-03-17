#!/usr/bin/env bash

source "scripts/lib/os.bash"
source "scripts/lib/pkg_manager.bash"
source "scripts/lib/http.bash"

declare -r LAZYGIT_PROGRAM_NAME="vscode"

declare -rA VSCODE_PACKAGES_BY_OS_ID=(
	["debian"]="code"
	["ubuntu"]="code"
	["rhel"]="code"
	["fedora"]="code"
	["alpine"]="code"
	["void"]="vscode"
	["arch"]="code"
)

declare -rA VSCODE_REPOSITORY_FILENAME_BY_OS_ID=(
	["debian"]="vscode.list"
	["ubuntu"]="vscode.list"
	["rhel"]="vscode.repo"
	["fedora"]="vscode.repo"
)

declare -rA VSCODE_SIGNING_KEY_FILENAME_BY_OS_ID=(
	["debian"]="microsoft.vscode.gpg"
	["ubuntu"]="microsoft.vscode.gpg"
)

function script_program_install() {
	local -r os_id="$(os_echo_id)" || exit $?
	case "$os_id" in
	arch | void)
		pkg_manager_install "${VSCODE_PACKAGES_BY_OS_ID[$os_id]}" || exit $?
		;;
	ubuntu | debian)
		local -ra dependency_packages=("gpg")
		pkg_manager_install "${dependency_packages[@]}"

		local -r signing_key_url="https://packages.microsoft.com/keys/microsoft.asc"
		local -r signing_key_filename="${VSCODE_SIGNING_KEY_FILENAME_BY_OS_ID[$os_id]}"
		pkg_manager_download_add_signing_key_dearmor "$signing_key_url" "$signing_key_filename"

		local -r repository_url="https://packages.microsoft.com/repos/code"
		local -r repository_filename="${VSCODE_REPOSITORY_FILENAME_BY_OS_ID[$os_id]}"
		local -r flags="stable main"
		pkg_manager_add_repo "$LAZYGIT_PROGRAM_NAME" "$repository_filename" "$repository_url" "$signing_key_filename" "$flags"
		pkg_manager_install "${VSCODE_PACKAGES_BY_OS_ID[$os_id]}" || exit $?
		;;
	rhen | fedora)
		local -ra dependency_packages=("gnupg")

		local -r repository_url="https://packages.microsoft.com/yumrepos/vscode"
		local -r signing_key_url="https://packages.microsoft.com/keys/microsoft.asc"
		local -r repository_filename="${VSCODE_REPOSITORY_FILENAME_BY_OS_ID[$os_id]}"
		local -r flags="autorefresh=1\ntype=rpm-md\ngpgcheck=1"
		pkg_manager_add_repo "$LAZYGIT_PROGRAM_NAME" "$repository_filename" "$repository_url" "$signing_key_url" "$flags"
		pkg_manager_install "${VSCODE_PACKAGES_BY_OS_ID[$os_id]}" || exit $?
		;;
	esac
}

function script_program_uninstall() {
	local -r os_id="$(os_echo_id)"

	case "$os_id" in
	arch | void | alpine | debian | ubuntu | rhel | fedora)
		pkg_manager_uninstall "${VSCODE_PACKAGES_BY_OS_ID[$os_id]}"
		pkg_manager_remove_repo "${VSCODE_REPOSITORY_FILENAME_BY_OS_ID[$os_id]}"

		case "$os_id" in
		debian | ubuntu)
			pkg_manager_remove_signing_key "${VSCODE_SIGNING_KEY_FILENAME_BY_OS_ID[$os_id]}"
			;;
		esac
		;;
	esac
}

source "scripts/ext/program_menu.bash"
