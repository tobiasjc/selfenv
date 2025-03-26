#!/usr/bin/env bash

source "scripts/lib/file.bash"

declare ___INSTALLER_ICONS_GLOBAL_DIRPATH="/usr/share/icons/hicolor"
declare ___INSTALLER_ICONS_LOCAL_DIRPATH="${HOME}/.local/share/icons/hicolor"

declare ___INSTALLER_ENV_RESOURCES_DIRPATH="resources"

declare ___INSTALLER_CONFIG_DIRPATH="${HOME}/.config"
declare ___INSTALLER_BASH_D_DIRPATH="${HOME}/.bashrc.d"

declare ___INSTALLER_GLOBAL_MAN_DIRPATH="/usr/share/man/man1"
declare ___INSTALLER_GLOBAL_INSTALL_DIRPATH="/usr/bin"
declare ___INSTALLER_GLOBAL_BASH_COMPLETION_D_DIRPATH="/etc/bash_completion.d"

declare ___INSTALLER_LOCAL_INSTALL_DIRPATH="${HOME}/.local/bin"
declare ___INSTALLER_LOCAL_APPLICATION_DIRPATH="${HOME}/.local/share/applications"
declare ___INSTALLER_GLOBAL_APPLICATION_DIRPATH="/usr/share/applications"

function installer_install_link_icon_global() {
	local -r filepath="$1"
	local -r link_name="$2"

	local size="$3"
	if [[ "$size" != *'x'* ]]; then
		size="${size}x${size}"
	fi

	local -r type="${4:-apps}"
	local -r target_dirpath="${___INSTALLER_ICONS_GLOBAL_DIRPATH}/${size}/${type}"
	(sudo mkdir --verbose --parents "$target_dirpath") || exit $?
	(sudo ln --verbose --force --symbolic "$filepath" "${target_dirpath}/${link_name}") || exit $?
}

function installer_install_link_icon_local() {
	local -r filepath="$1"
	local -r link_name="$2"

	local size="$3"
	if [[ "$size" != *'x'* ]]; then
		size="${size}x${size}"
	fi

	local -r type="${4:-apps}"
	local -r target_dirpath="${___INSTALLER_ICONS_LOCAL_DIRPATH}/${size}/${type}"
	(mkdir --verbose --parents "$target_dirpath") || exit $?
	(ln --verbose --force --symbolic "$filepath" "${target_dirpath}/${link_name}") || exit $?
}

function installer_install_icon_global() {
	local -r filepath="$1"
	local -r size="$2"

	if [[ "$size" != *'x'* ]]; then
		size="${size}x${size}"
	fi

	local -r type="${4:-apps}"
	local -r target_dirpath="${___INSTALLER_ICONS_GLOBAL_DIRPATH}/${size}/${type}"
	(sudo mkdir --verbose --parents "$target_dirpath") || exit $?
	(sudo cp --verbose "$filepath" "${target_dirpath}/${link_name}") || exit $?
}

function installer_install_icon_local() {
	local -r filepath="$1"
	local -r size="$2"

	if [[ "$size" != *'x'* ]]; then
		size="${size}x${size}"
	fi

	local -r type="${4:-apps}"
	local -r target_dirpath="${___INSTALLER_ICONS_LOCAL_DIRPATHGLOBAL_DIRPATH}/${size}/${type}"
	(mkdir --verbose --parents "$target_dirpath") || exit $?
	(cp --verbose "$filepath" "${target_dirpath}/${link_name}") || exit $?
}

function installer_uninstall_icon_global() {
	local -r name="$1"

	local size="$2"
	if [[ "$size" != *'x'* ]]; then
		size="${size}x${size}"
	fi

	local -r type="${3:-apps}"
	local -r dirpath="${___INSTALLER_ICONS_GLOBAL_DIRPATH}/${size}/${type}"
	(rm --verbose --force "${dirpath}/${name}") || exit $?
}

function installer_uninstall_icon_local() {
	local -r name="$1"

	local size="$2"
	if [[ "$size" != *'x'* ]]; then
		size="${size}x${size}"
	fi

	local -r type="${3:-apps}"
	local -r dirpath="${___INSTALLER_ICONS_LOCAL_DIRPATH}/${size}/${type}"
	(rm --verbose --force "${dirpath}/${name}") || exit $?
}

function installer_install_man1() {
	local -r filepath="$1"
	(sudo install --verbose "$filepath" "$___INSTALLER_GLOBAL_MAN_DIRPATH" &&
		sudo mandb) || exit $?
}

function installer_uninstall_man1() {
	local -r man_name="$1"
	(sudo rm --verbose --recursive --force "${___INSTALLER_GLOBAL_MAN_DIRPATH}/${man_name}" &&
		sudo mandb) || exit $?
}

function installer_install_global_bin() {
	local -r filepath="$1"
	(sudo install --verbose "$filepath" "$___INSTALLER_GLOBAL_INSTALL_DIRPATH") || exit $?
}

function installer_install_local_bin() {
	local -r filepath="$1"
	(install --verbose "$filepath" "$___INSTALLER_LOCAL_INSTALL_DIRPATH") || exit $?
}

function installer_uninstall_global_bin() {
	local -r name="$1"
	(sudo rm --verbose --force "${___INSTALLER_GLOBAL_INSTALL_DIRPATH}/${name}") || exit $?
}

function installer_uninstall_local_bin() {
	local -r name="$1"
	(rm --verbose --force "${___INSTALLER_LOCAL_INSTALL_DIRPATH}/${name}") || exit $?
}

function installer_install_global_link_bin() {
	local -r target="$1"
	local -r name="$2"
	(sudo ln --verbose --force --symbolic "$target" "${___INSTALLER_GLOBAL_INSTALL_DIRPATH}/${name}") || exit $?
}

function installer_install_local_link_bin() {
	local -r target="$1"
	local -r name="$2"
	(ln --verbose --force --symbolic "$target" "${___INSTALLER_LOCAL_INSTALL_DIRPATH}/${name}") || exit $?
}

function installer_install_completion() {
	local -r filepath="$1"
	(sudo install --verbose "${filepath}" "${___INSTALLER_GLOBAL_BASH_COMPLETION_D_DIRPATH}") || exit $?
}

function installer_install_command_completion() {
	local -r name="$1"
	local -r command="$2"

	local -r filepath="${___INSTALLER_GLOBAL_BASH_COMPLETION_D_DIRPATH}/${name}"
	(eval "$command" | sudo tee "$filepath") || exit $?
}

function installer_uninstall_completion() {
	local -r name="$1"
	(sudo rm --verbose --recursive --force "${___INSTALLER_GLOBAL_BASH_COMPLETION_D_DIRPATH:?}/${name}") || exit $?
}

function installer_install_desktop_file_local() {
	local name="${1:?}"
	shift
	local -ra opts=("$@")

	if [[ "$name" != *.desktop ]]; then
		name+=".desktop"
	fi

	(desktop-file-install --dir="$___INSTALLER_LOCAL_APPLICATION_DIRPATH" --rebuild-mime-info-cache "${opts[@]}" "resources/default.desktop" &&
		mv --verbose "${___INSTALLER_LOCAL_APPLICATION_DIRPATH:?}/default.desktop" "${___INSTALLER_LOCAL_APPLICATION_DIRPATH:?}/${name}" &&
		sudo update-desktop-database) || exit $?
}

function installer_install_desktop_file_local_from_filepath() {
	local filepath="${1:?}"
	shift
	local -ra opts=("$@")

	if [[ "$name" != *.desktop ]]; then
		name+=".desktop"
	fi

	(desktop-file-install --dir="$___INSTALLER_LOCAL_APPLICATION_DIRPATH" --rebuild-mime-info-cache "${opts[@]}" "$filepath" &&
		sudo update-desktop-database) || exit $?
}

function installer_uninstall_desktop_file_local() {
	local -r name="$1"

	(rm --verbose --recursive --force "${___INSTALLER_LOCAL_APPLICATION_DIRPATH:?}/${name}" &&
		sudo update-desktop-database) || exit $?
}

function installer_install_desktop_file_global() {
	local name="${1:?}"
	shift
	local -ra opts=("$@")

	if [[ "$name" != *.desktop ]]; then
		name+=".desktop"
	fi

	(sudo desktop-file-install --dir="$___INSTALLER_GLOBAL_APPLICATION_DIRPATH" --rebuild-mime-info-cache "${opts[@]}" "resources/default.desktop" &&
		mv --verbose "${___INSTALLER_GLOBAL_APPLICATION_DIRPATH:?}/default.desktop" "${___INSTALLER_GLOBAL_APPLICATION_DIRPATH:?}/${name}" &&
		sudo update-desktop-database) || exit $?
}

function installer_install_desktop_file_global_from_filepath() {
	local filepath="${1:?}"
	shift
	local -ra opts=("$@")

	if [[ "$name" != *.desktop ]]; then
		name+=".desktop"
	fi

	(sudo desktop-file-install --dir="$___INSTALLER_GLOBAL_APPLICATION_DIRPATH" --rebuild-mime-info-cache "${opts[@]}" "$filepath" &&
		sudo update-desktop-database) || exit $?
}

function installer_uninstall_desktop_file_global() {
	local -r name="$1"

	(sudo rm --verbose --recursive --force "${___INSTALLER_LOCAL_APPLICATION_DIRPATH:?}/${name}" &&
		sudo update-desktop-database) || exit $?
}

function installer_install_config_resource() {
	local -r name="$1"
	local -r to="${2:-${name}}"

	(mkdir --parents "${___INSTALLER_CONFIG_DIRPATH}" &&
		cp --verbose --recursive --force "${___INSTALLER_ENV_RESOURCES_DIRPATH}/${name}" "${___INSTALLER_CONFIG_DIRPATH}/${to}") || exit $?
}

function installer_uninstall_config_resource() {
	local -r name="$1"
	(rm --verbose --recursive --force "${___INSTALLER_CONFIG_DIRPATH:?}/${name}") || exit $?
}

function installer_install_bashrc_d_resource() {
	local -r name="$1"
	local -r to="${2:-${name}}"

	(mkdir --parents "${___INSTALLER_BASH_D_DIRPATH}" &&
		cp --verbose --recursive --force "${___INSTALLER_ENV_RESOURCES_DIRPATH}/${name}" "${___INSTALLER_BASH_D_DIRPATH}/${to}") || exit $?
}

function installer_uninstall_bashrc_d_resource() {
	local -r name="$1"
	(rm --verbose --recursive --force "${___INSTALLER_BASH_D_DIRPATH:?}/${name}") || exit $?
}
