#!/usr/bin/env bash

function system_arch_base_system() {
	local -ra security=("gnupg")
	local -ra build=("base-devel" "git" "make" "automake" "cmake" "ninja" "llvm")
	local -ra net=("openssh" "aria2" "curl" "wget")
	local -ra files=("zip" "unzip" "bzip2" "tar")

	(sudo pacman --needed --noconfirm -Syu &&
		sudo pacman --needed --noconfirm -Sy "${security[@]}" "${build[@]}" "${net[@]}" "${files[@]}") || exit ?
}

function system_arch_aur_helper_aura() {
	local -r git_url="https://aur.archlinux.org/aura.git"
	local -r clone_target_dir="/tmp/aura"

	rm --verbose --recursive --force "${clone_target_dir}"
	sudo pacman -Syu
	if pacman -Q aura; then
		return 0
	fi

	(git clone "$git_url" "$clone_target_dir" &&
		cd "$clone_target_dir" &&
		makepkg --needed --syncdeps --noconfirm --install &&
		rm --verbose --recursive --force "$clone_target_dir") || exit $?
}

function system_arch_qol() {
	local -ra packages=("bash-completion" "man" "man-pages" "man-db")
	(sudo pacman --needed --noconfirm -Syu &&
		sudo pacman --needed --noconfirm -Sy "${packages[@]}" &&
		sudo mandb -c) || exit $?
}

function system_arch_desktop_environment() {
	local -r desktop_environment="$(echo "${DESKTOP_SESSION,,}" | tr --delete '[:punct:]' | tr --delete '[:cntrl:]' | tr '[:upper:]' '[:lower:]')"
	case "$desktop_environment" in
	xfce | xfce4)
		local -ra packages=("xfce4-goodies")
		(sudo pacman --needed --noconfirm -Syu &&
			sudo pacman --needed --noconfirm -Sy "${packages[@]}") || exit $?
		;;
	gnome) ;;
	kde) ;;
	esac
}

function run() {
	system_arch_base_system
	system_arch_aur_helper_aura
	system_arch_desktop_environment
	system_arch_qol
}

run
