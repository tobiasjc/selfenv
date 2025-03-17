#!/usr/bin/env bash

source "scripts/lib/git.bash"
source "scripts/lib/os.bash"
source "scripts/lib/http.bash"
source "scripts/lib/file.bash"
source "scripts/lib/pkg_manager.bash"

declare -r STARSHIP_EXECUTABLE_NAME="starship"
declare -r STARSHIP_EXECUTABLE_INSTALL_DIRPATH="/usr/bin"
declare -r STARSHIP_EXECUTABLE_FILEPATH="${STARSHIP_EXECUTABLE_INSTALL_DIRPATH}/${STARSHIP_EXECUTABLE_NAME}"

declare -r STARSHIP_REPOSITORY_URL="https://github.com/starship/starship"
declare -r STARSHIP_RAW_DOWNLOAD_URL="https://github.com/starship/starship/releases/download/@{{version_tag}}/starship-@{{architecture}}-unknown-linux-gnu.tar.gz"
declare -r STARSHIP_DOWNLOAD_DIRPATH="/tmp/starship"
declare -r STARSHIP_DOWNLOAD_FILENAME="starship.tar.gz"
declare -r STARSHIP_DOWNLOAD_FILEPATH="${STARSHIP_DOWNLOAD_DIRPATH}/${STARSHIP_DOWNLOAD_FILENAME}"

declare -r STARSHIP_RESOURCE_CONFIG_FILENAME="starship.toml"
declare -r STARSHIP_RESOURCE_BASH_D_FILENAME="starship.bash"

function script_program_install() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | void | alpine)
		pkg_manager_install "starship"
		(file_config_resource_install "$STARSHIP_RESOURCE_CONFIG_FILENAME" &&
			file_bashrc_d_resource_install "$STARSHIP_RESOURCE_BASH_D_FILENAME") || exit $?
		;;
	debian | ubuntu | rhel | fedora)
		local -r version_tag="$(git_echo_latest_tag "$STARSHIP_REPOSITORY_URL")"
		local -r machine_architecture="$(os_echo_machine_architecture)"
		local -r download_url="$(echo "$STARSHIP_RAW_DOWNLOAD_URL" |
			sed -e "s/@{{version_tag}}/$version_tag/g" |
			sed -e "s/@{{architecture}}/$machine_architecture/g")"

		http_download "$download_url" "$STARSHIP_DOWNLOAD_DIRPATH" "$STARSHIP_DOWNLOAD_FILENAME"
		(tar --verbose --extract --directory="$STARSHIP_DOWNLOAD_DIRPATH" --file="$STARSHIP_DOWNLOAD_FILEPATH" &&
			sudo install --verbose "${STARSHIP_DOWNLOAD_DIRPATH}/${STARSHIP_EXECUTABLE_NAME}" "$STARSHIP_EXECUTABLE_INSTALL_DIRPATH" &&
			file_config_resource_install "$STARSHIP_RESOURCE_CONFIG_FILENAME" &&
			file_bashrc_d_resource_install "$STARSHIP_RESOURCE_BASH_D_FILENAME") || exit $?

		rm --verbose --recursive --force "$STARSHIP_DOWNLOAD_DIRPATH"
		;;
	esac
}

function script_program_uninstall() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | void | alpine)
		(pkg_manager_uninstall "starship" &&
			file_config_resource_uninstall "$STARSHIP_RESOURCE_CONFIG_FILENAME" &&
			file_bashrc_d_resource_uninstall "$STARSHIP_RESOURCE_BASH_D_FILENAME") || exit $?
		;;
	debian | ubuntu | rhel | fedora)
		(sudo rm --verbose --recursive --force "${STARSHIP_EXECUTABLE_FILEPATH}" &&
			file_config_resource_uninstall "$STARSHIP_RESOURCE_CONFIG_FILENAME" &&
			file_bashrc_d_resource_uninstall "$STARSHIP_RESOURCE_BASH_D_FILENAME") || exit $?
		;;
	esac
}

source "scripts/ext/program_menu.bash"
