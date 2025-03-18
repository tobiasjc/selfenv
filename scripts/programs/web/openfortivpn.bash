#!/usr/bin/env bash

source "scripts/lib/git.bash"
source "scripts/lib/os.bash"
source "scripts/lib/pkg_manager.bash"

declare -r EXECUTABLE_NAME="openfortivpn"

declare -r INSTALL_PREFIX_DIR="/usr/local"
declare -r INSTALL_PREFIX_CONFIG_DIR="/etc"

declare -r GIT_REPO_URL="https://github.com/adrienverge/openfortivpn/"
declare -r GIT_CLONE_DIR="/tmp/${EXECUTABLE_NAME}"

declare -r BUILD_DEPENDENCIES=("gcc" "llvm" "make" "automake" "autoconf")

function script_program_install() {
	local -r version="${1:-latest}"

	git_clone "$GIT_REPO_URL" "$version" "$GIT_CLONE_DIR" "true"

	# 1. install dependencies
	pkg_manager_install "${BUILD_DEPENDENCIES[@]}"

	# 2. build
	(cd "$GIT_CLONE_DIR" &&
		./autogen.sh &&
		./configure --prefix="${INSTALL_PREFIX_DIR}" --sysconfdir="${INSTALL_PREFIX_CONFIG_DIR}" &&
		make) || exit $?

	# 3. install
	(cd "$GIT_CLONE_DIR" &&
		sudo make install &&
		rm --recursive --force "$GIT_CLONE_DIR") || exit $?
}

function script_program_uninstall() {
	(sudo rm --verbose --recursive --force "${INSTALL_PREFIX_DIR}/bin/${EXECUTABLE_NAME:?}" &&
		sudo rm --verbose --recursive --force "${INSTALL_PREFIX_DIR}/share/${EXECUTABLE_NAME:?}" &&
		sudo rm --verbose --recursive --force "${INSTALL_PREFIX_CONFIG_DIR}/${EXECUTABLE_NAME:?}") || exit $?
}

source "scripts/ext/program_menu.bash"
