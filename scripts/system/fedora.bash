#!/usr/bin/env bash

source "scripts/lib/os.bash"
source "scripts/lib/git.bash"
source "scripts/lib/pkg_manager.bash"

function install_base_build_system() {
	local -ra packages=("@development-tools" "git" "make" "automake" "cmake" "ninja" "llvm")
	pkg_manager_install "${packages[@]}"
}

function run() {
	install_base_build_system
}

run
