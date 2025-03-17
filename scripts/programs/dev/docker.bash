#!/usr/bin/env bash

source "scripts/lib/os.bash"
source "scripts/lib/pkg_manager.bash"
source "scripts/lib/http.bash"

declare -r DOCKER_PROGRAM_NAME="docker"
declare -r DOCKER_CE_PACKAGES=("docker-ce" "docker-ce-cli" "containerd.io" "docker-buildx-plugin" "docker-compose-plugin")
declare -r DOCKER_COMMON_PACKAGES=("docker" "docker-buildx" "docker-compose")

declare -rA DOCKER_REPOSITORY_FILENAME_BY_OS_ID=(
	["debian"]="docker.list"
	["ubuntu"]="docker.list"
	["rhel"]="docker.repo"
	["fedora"]="docker.repo"
)

declare -rA DOCKER_SIGNING_KEY_FILENAME_BY_OS_ID=(
	["debian"]="docker.asc"
	["ubuntu"]="docker.asc"
)

function script_program_install() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | void | alpine)
		pkg_manager_install "${DOCKER_COMMON_PACKAGES[@]}"
		;;
	debian | ubuntu)
		local -r kernel_name="$(os_echo_kernel_name)"

		local -ar dependency_packages=("ca-certificates")
		pkg_manager_install "${dependency_packages[@]}"

		local -r signing_key_url="https://download.docker.com/${kernel_name}/${os_id}/gpg"
		local -r signing_key_filename="${DOCKER_SIGNING_KEY_FILENAME_BY_OS_ID[$os_id]}"
		pkg_manager_download_add_signing_key "$signing_key_url" "$signing_key_filename"

		local -r repository_url="https://download.docker.com/${kernel_name}/${os_id}"
		local -r repository_filename="${DOCKER_REPOSITORY_FILENAME_BY_OS_ID[$os_id]}"
		local -r repository_flags="$(os_query_release_file "VERSION_CODENAME") stable"
		pkg_manager_add_repo "$DOCKER_PROGRAM_NAME" "$repository_filename" "$repository_url" "$signing_key_filename" "$repository_flags"
		pkg_manager_install "${DOCKER_CE_PACKAGES[@]}"
		script_program_post_install
		;;
	rhel | fedora)
		local -r kernel_name="$(os_echo_kernel_name)"
		local -r version_id="$(os_query_release_file "VERSION_ID")"
		local -r machine_architecture="$(os_echo_machine_architecture)"

		local -r repository_url="https://download.docker.com/${kernel_name}/${os_id}/${version_id}/${machine_architecture}/stable"
		local -r signing_key_url="https://download.docker.com/${kernel_name}/${os_id}/gpg"
		local -r repository_filename="${DOCKER_REPOSITORY_FILENAME_BY_OS_ID[$os_id]}"

		pkg_manager_add_repo "$DOCKER_PROGRAM_NAME" "$repository_filename" "$repository_url" "$signing_key_url"
		pkg_manager_install "${DOCKER_CE_PACKAGES[@]}"
		script_program_post_install
		;;
	esac
}

function script_program_post_install() {
	(sudo groupadd --force docker &&
		sudo usermod --append --groups docker "$USER") || exit $?
	(sudo systemctl enable docker &&
		sudo systemctl start docker) || exit $?
}

function script_program_uninstall() {
	local -r os_id="$(os_echo_id)"

	case "$os_id" in
	arch | void | alpine)
		pkg_manager_uninstall "${DOCKER_COMMON_PACKAGES[@]}"
		;;
	debian | ubuntu | rhel | fedora)
		pkg_manager_uninstall "${DOCKER_CE_PACKAGES[@]}"
		pkg_manager_remove_repo "${DOCKER_REPOSITORY_FILENAME_BY_OS_ID[$os_id]}"

		case "$os_id" in
		debian | ubuntu)
			pkg_manager_remove_signing_key "${DOCKER_SIGNING_KEY_FILENAME_BY_OS_ID[$os_id]}"
			;;
		esac
		;;
	esac
}

source "scripts/ext/program_menu.bash"
