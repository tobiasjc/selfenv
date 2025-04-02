#!/usr/bin/env bash

source "scripts/lib/git.bash"
source "scripts/lib/os.bash"
source "scripts/lib/http.bash"
source "scripts/lib/installer.bash"
source "scripts/lib/pkg_manager.bash"

declare -r STARSHIP_BIN_NAME="starship"

declare -r STARSHIP_RESOURCE_CONFIG_FILENAME="starship.toml"
declare -r STARSHIP_RESOURCE_BASH_D_FILENAME="starship.bash"
declare -rA STARSHIP_PKG_NAME_BY_OS_ID=(
	["arch"]="starship"
	["void"]="starship"
	["alpine"]="starship"
)

function script_program_install() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | void | alpine | debian | ubuntu | fedora)
		installer_install_config_resource "$STARSHIP_RESOURCE_CONFIG_FILENAME"
		installer_install_bashrc_d_resource "$STARSHIP_RESOURCE_BASH_D_FILENAME"

		case "$os_id" in
		arch | void | alpine)
			local -r pkg_name="${STARSHIP_PKG_NAME_BY_OS_ID[$os_id]}"
			pkg_manager_install "$pkg_name"
			;;
		debian | ubuntu | fedora)
			# 1. versioning
			local -r repository_url="https://github.com/starship/starship"
			local -r version_tag="$(git_echo_latest_tag "$repository_url" '--sort=version:refname' '^v[0-9]+\.[0-9]+\.[0-9]+$')"
			local -r machine_architecture="$(os_echo_machine_architecture)"
			local -r kernel_name="$(os_echo_kernel_name)"

			# 2. download
			local -r download_dirpath="/tmp/starship"

			local -r download_url="https://github.com/starship/starship/releases/download/${version_tag}/starship-${machine_architecture}-unknown-${kernel_name}-gnu.tar.gz"
			local -r download_filename="starship.tar.gz"
			http_download "$download_url" "$download_dirpath" "$download_filename"

			# 3. prepare install
			local -r download_filepath="${download_dirpath}/${download_filename}"
			tar --verbose --extract --directory="$download_dirpath" --file="$download_filepath" || exit $?

			# 4. install
			installer_install_bin_global "${download_dirpath}/${STARSHIP_BIN_NAME}"

			# 5. clear
			(rm --verbose --recursive --force "$download_dirpath") || exit $?
			;;
		esac
		;;
	esac
}

function script_program_uninstall() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | void | alpine | debian | ubuntu | fedora)
		installer_uninstall_config "$STARSHIP_RESOURCE_CONFIG_FILENAME"
		installer_uninstall_bashrc_d "$STARSHIP_RESOURCE_BASH_D_FILENAME"

		case "$os_id" in
		arch | void | alpine)
			local -r pkg_name="${STARSHIP_PKG_NAME_BY_OS_ID[$os_id]}"
			pkg_manager_uninstall "$pkg_name"
			;;
		debian | ubuntu | fedora)
			installer_uninstall_bin_global "$STARSHIP_BIN_NAME"
			;;
		esac
		;;
	esac
}

source "scripts/ext/program_menu.bash"
