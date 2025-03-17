#!/usr/bin/env bash

source "scripts/lib/git.bash"
source "scripts/lib/os.bash"
source "scripts/lib/http.bash"
source "scripts/lib/pkg_manager.bash"

declare -rA DBEAVER_PACKAGE_BY_OS_ID=(
	["arch"]="dbeaver"
	["void"]="dbeaver"
	["debian"]="dbeaver-ce"
	["ubuntu"]="dbeaver-ce"
	["rhel"]="dbeaver-ce"
	["fedora"]="dbeaver-ce"
)

declare -rA DBEAVER_REPOSITORY_FILENAME_BY_OS_ID=(
	["debian"]="dbeaver-ce.list"
	["ubuntu"]="dbeaver-ce.list"
)

declare -rA DBEAVER_SIGNING_KEY_FILENAME_BY_OS_ID=(
	["debian"]="dbeaver.gpg.key"
	["ubuntu"]="dbeaver.gpg.key"
)

function script_program_install() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | void)
		pkg_manager_install "${DBEAVER_PACKAGE_BY_OS_ID[$os_id]}"
		;;
	debian | ubuntu)
		local -r signing_key_url="https://dbeaver.io/debs/dbeaver.gpg.key"
		local -r signing_key_filename="${DBEAVER_SIGNING_KEY_FILENAME_BY_OS_ID[$os_id]}"
		pkg_manager_download_add_signing_key "$signing_key_url" "$signing_key_filename"

		local -r repository_url="https://dbeaver.io/debs/dbeaver-ce"
		local -r repository_name="${DBEAVER_PACKAGE_BY_OS_ID[$os_id]}"
		local -r repository_filename="${DBEAVER_REPOSITORY_FILENAME_BY_OS_ID[$os_id]}"
		pkg_manager_add_repo "$repository_name" "$repository_filename" "$repository_url" "$signing_key_filename" "/"
		pkg_manager_install "$repository_package_name"
		;;
	rhel | fedora)
		local -r version="$(git_echo_latest_tag "https://github.com/dbeaver/dbeaver" | sed -e "s/release_//")"

		local -r raw_download_url="https://github.com/dbeaver/dbeaver/releases/download/@{{version}}/dbeaver-ce-@{{version}}-stable.@{{architecture}}.@{{extension}}"
		local -r machine_architecture="$(os_echo_machine_architecture)"
		local -r pkg_extension="$(pkg_manager_echo_pkg_extension)"
		local -r download_url="$(echo "$raw_download_url" |
			sed -e "s/@{{version}}/$version/g" |
			sed -e "s/@{{architecture}}/$machine_architecture/g" |
			sed -e "s/@{{extension}}/$pkg_extension/g")"

		local -r download_output_dir="/tmp"
		local -r download_filename="dbeaver.${pkg_extension}"
		local -r download_filepath="${download_output_dir}/${download_filename}"
		http_download "$download_url" "$download_output_dir" "$download_filename"
		pkg_manager_install "$download_filepath"

		local -r repository_package_name="${DBEAVER_PACKAGE_BY_OS_ID[$os_id]}"
		pkg_manager_install "$repository_package_name"
		;;
	esac
}

function script_program_uninstall() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | void | debian | ubuntu | rhel | fedora)
		pkg_manager_uninstall "${DBEAVER_PACKAGE_BY_OS_ID[$os_id]}"

		case "$os_id" in
		debian | ubuntu)
			pkg_manager_remove_repo "${DBEAVER_REPOSITORY_FILENAME_BY_OS_ID[$os_id]}"
			pkg_manager_remove_signing_key "${DBEAVER_SIGNING_KEY_FILENAME_BY_OS_ID[$os_id]}"
			;;
		esac
		;;
	esac
}

source "scripts/ext/program_menu.bash"
