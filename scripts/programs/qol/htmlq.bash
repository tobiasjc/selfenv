#!/usr/bin/env bash

source "scripts/lib/os.bash"
source "scripts/lib/git.bash"
source "scripts/lib/http.bash"
source "scripts/lib/pkg_manager.bash"

declare -rA HTMLQ_PACKAGES_BY_OS_ID=(
	["arch"]="htmlq"
	["alpine"]="htmlq"
)

declare -r HTMLQ_EXECUTABLE_NAME="htmlq"
declare -r HTMLQ_EXECUTABLE_DIR="/usr/bin"
declare -r HTMLQ_EXECUTABLE_FILEPATH="${HTMLQ_EXECUTABLE_DIR}/${HTMLQ_EXECUTABLE_NAME}"
declare -r HTMLQ_REPOSITORY_URL="https://github.com/mgdm/htmlq"
declare -r HTMLQ_RAW_DOWNLOAD_URL="https://github.com/mgdm/htmlq/releases/download/@{{version_tag}}/htmlq-@{{architecture}}-@{{kernel_name}}.tar.gz"

function script_program_install() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | alpine)
		pkg_manager_install "${HTMLQ_PACKAGES_BY_OS_ID[$os_id]}"
		;;
	debian | ubuntu | rhel | fedora)
		local -r version_tag="$(git_echo_latest_tag "$HTMLQ_REPOSITORY_URL")"
		local -r architecture="$(os_echo_machine_architecture)"
		local -r kernel_name="$(os_echo_kernel_name)"
		local -r download_url="$(echo "$HTMLQ_RAW_DOWNLOAD_URL" |
			sed -e "s/@{{version_tag}}/$version_tag/g" |
			sed -e "s/@{{architecture}}/$architecture/g" |
			sed -e "s/@{{kernel_name}}/$kernel_name/g")" || exit $?

		local -r download_output_dir="/tmp/htmlq"
		local -r download_filename="htmlq.tar.gz"
		local -r download_filepath="${download_output_dir}/${download_filename}"
		http_download "$download_url" "$download_output_dir" "$download_filename"
		(tar --verbose --extract --directory="$download_output_dir" --file="$download_filepath" &&
			sudo install --verbose "${download_output_dir}/${HTMLQ_EXECUTABLE_NAME}" "$HTMLQ_EXECUTABLE_DIR") || exit $?
		;;
	esac
}

function script_program_uninstall() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | alpine)
		pkg_manager_uninstall "${HTMLQ_PACKAGES_BY_OS_ID[$os_id]}"
		;;
	debian | ubuntu | rhel | fedora)
		(sudo rm --verbose --recursive --force "$HTMLQ_EXECUTABLE_FILEPATH") || exit $?
		;;
	esac
}

source "scripts/ext/program_menu.bash"
