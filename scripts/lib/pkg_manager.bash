#!/usr/bin/env bash

source "scripts/lib/os.bash"
source "scripts/lib/array.bash"
source "scripts/lib/log.bash"
source "scripts/lib/http.bash"

declare -A ___PKG_MANAGER_CALL_PREFIXES=(
	["apt"]="sudo "
	["dnf"]="sudo "
	["apk"]="sudo "
	["xbps"]="sudo "
	["pacman"]="sudo "
)
declare ___PKG_MANAGER_CALL_PREFIX=""

declare -A ___PKG_MANAGER_OS_TO_PKG_MANAGERS=(
	["debian"]="apt"
	["ubuntu"]="apt"
	["fedora"]="dnf"
	["alpine"]="apk"
	["void"]="xbps"
	["arch"]="pacman aura"
)
declare ___PKG_MANAGER_EXECS=""

declare -A ___PKG_MANAGER_TO_EXTENSION=(
	["apt"]="deb"
	["dnf"]="rpm"
	["apk"]="apk"
	["xbps"]="xbps"
	["pacman"]="pkg"
	["aura"]="pkg"
)
declare ___PKG_MANAGER_EXT=""

declare -A ___PKG_MANAGER_TO_INSTALL_CMD=(
	["apt"]=" install --yes "
	["dnf"]=" install --assumeyes"
	["apk"]=" add --no-interactive "
	["xbps"]="-install --yes"
	["pacman"]=" --needed --sync --noconfirm "
	["aura"]=" --aursync --noconfirm "
)
declare ___PKG_MANAGER_INSTALL_CMDS=""

declare -A ___PKG_MANAGER_TO_UNINSTALL_CMD=(
	["apt"]=" remove --yes"
	["dnf"]=" remove --assumeyes"
	["apk"]=" del --no-interactive"
	["xbps"]="-remove --yes"
	["pacman"]=" --remove --noconfirm"
	["aura"]=" --remove --noconfirm"
)
declare ___PKG_MANAGER_UNINSTALL_CMDS=""

declare -A ___PKG_MANAGER_TO_UPDATE_CMD=(
	["apt"]=" update --yes"
	["dnf"]=" update --assumeyes"
	["apk"]=" update --no-interactive"
	["xbps"]="-install --sync --update --yes"
	["pacman"]=" --sync --refresh --sysupgrade --noconfirm"
	["aura"]=" --aursync --sysupgrade --noconfirm"
)
declare ___PKG_MANAGER_UPDATE_CMDS=""

declare -A ___PKG_MANAGER_REPOSITORY_DIRPATH_BY_OS_ID=(
	["debian"]="/etc/apt/sources.list.d"
	["ubuntu"]="/etc/apt/sources.list.d"
	["fedora"]="/etc/yum.repos.d"
)

declare -A ___PKG_MANAGER_REPOSITORY_SIGNING_KEY_DIRPATH_BY_OS_ID=(
	["debian"]="/etc/apt/keyrings"
	["ubuntu"]="/etc/apt/keyrings"
)

function pkg_manager_install() {
	local -r packages=("$@")

	local -i success=1
	local -r update_cmds="$(pkg_manager_echo_managers_update)"
	local IFS='&'
	for cmd in $update_cmds; do
		if eval "sudo $cmd"; then
			success=0
		fi
	done
	unset IFS
	if [ $success -ne 0 ]; then
		exit 1
	fi

	local -i success=1
	local -r install_cmds="$(pkg_manager_echo_managers_install)"
	local -r direct_packages="${packages[*]}"
	local IFS='&'
	for cmd in $install_cmds; do
		if (eval "$cmd $direct_packages"); then
			success=0
			break
		fi
	done
	unset IFS
	if [ $success -ne 0 ]; then
		exit 1
	fi
}

function pkg_manager_uninstall() {
	local -r packages=("$@")

	local -r cmd="sudo $(pkg_manager_echo_managers_uninstall)"
	eval "${cmd} ${packages[*]}" || exit $?
}

function pkg_manager_echo_os_pkg_managers() {
	if [ -n "$___PKG_MANAGER_EXECS" ]; then
		echo -n "$___PKG_MANAGER_EXECS"
		return 0
	fi

	local -r os_id="$(os_echo_id)"
	local -r pkg_managers="${___PKG_MANAGER_OS_TO_PKG_MANAGERS[$os_id]}"
	if [ -z "$pkg_managers" ]; then
		exit 1
	fi

	___PKG_MANAGER_EXECS="$pkg_managers"
	echo -n "$pkg_managers"
}

function pkg_manager_echo_managers_install() {
	if [ -n "$___PKG_MANAGER_INSTALL_CMDS" ]; then
		echo -n "$___PKG_MANAGER_INSTALL_CMDS"
		return 0
	fi

	local install_cmds_array=()
	local -r pkg_managers="$(pkg_manager_echo_os_pkg_managers)"
	for pkg_manager in $pkg_managers; do
		local install_cmd="${___PKG_MANAGER_TO_INSTALL_CMD["$pkg_manager"]}"
		local call_prefix="${___PKG_MANAGER_CALL_PREFIXES["$pkg_manager"]}"
		if [ -n "$install_cmd" ]; then
			install_cmds_array+=("${call_prefix}${pkg_manager}${install_cmd}")
		fi
	done
	if [ "${#install_cmds_array[@]}" == 0 ]; then
		exit 1
	fi

	local -r install_cmds="$(array_echo_concat_string "&" "${install_cmds_array[@]}")"
	___PKG_MANAGER_INSTALL_CMDS="$install_cmds"
	echo -n "$install_cmds"
}

function pkg_manager_echo_managers_uninstall() {
	if [ -n "$___PKG_MANAGER_UNINSTALL_CMDS" ]; then
		echo -n "$___PKG_MANAGER_UNINSTALL_CMDS"
		return 0
	fi

	local uninstall_cmds_array=()
	local -r pkg_managers="$(pkg_manager_echo_os_pkg_managers)"
	for pkg_manager in $pkg_managers; do
		local uninstall_cmd="${___PKG_MANAGER_TO_UNINSTALL_CMD["$pkg_manager"]}"
		if [ -n "$uninstall_cmd" ]; then
			uninstall_cmds_array+=("${pkg_manager}${uninstall_cmd}")
		fi
	done
	if [ "${#uninstall_cmds_array[@]}" == 0 ]; then
		exit 1
	fi

	local -r uninstall_cmds="$(array_echo_concat_string "&" "${uninstall_cmds_array[@]}")"
	___PKG_MANAGER_UNINSTALL_CMDS="$uninstall_cmds"
	echo -n "$uninstall_cmds"
}

function pkg_manager_echo_managers_update() {
	if [ -n "$___PKG_MANAGER_UPDATE_CMDS" ]; then
		echo -n "$___PKG_MANAGER_UPDATE_CMDS"
		return 0
	fi

	local update_cmds_array=()
	local -r pkg_managers="$(pkg_manager_echo_os_pkg_managers)"
	for pkg_manager in $pkg_managers; do
		local update_cmd="${___PKG_MANAGER_TO_UPDATE_CMD["$pkg_manager"]}"
		if [ -n "$update_cmd" ]; then
			update_cmds_array+=("${pkg_manager}${update_cmd}")
		fi
	done
	if [ "${#update_cmds_array[@]}" == 0 ]; then
		exit 1
	fi

	local -r update_cmds="$(array_echo_concat_string "&" "${update_cmds_array[@]}")"
	___PKG_MANAGER_UPDATE_CMDS="$update_cmds"
	echo -n "$update_cmds"
}

function pkg_manager_echo_pkg_extension() {
	if [ -n "$___PKG_MANAGER_EXT" ]; then
		echo -n "$___PKG_MANAGER_EXT"
		return 0
	fi

	local -r pkg_manager="$(pkg_manager_echo_os_pkg_managers)"
	local -r ext="${___PKG_MANAGER_TO_EXTENSION[$pkg_manager]}"
	if [ -z "$ext" ]; then
		exit 1
	fi

	___PKG_MANAGER_EXT="$ext"
	echo -n "$ext"
}

function pkg_manager_download_add_signing_key_dearmor() {
	local -r url="$1"
	local -r filename="$2"

	local -r os_id="$(os_echo_id)"
	local -r dirpath="${___PKG_MANAGER_REPOSITORY_SIGNING_KEY_DIRPATH_BY_OS_ID[$os_id]}"
	if [ -z "$dirpath" ]; then
		log_kill "os id '$os_id' does not have a dirpath set for signing keys"
	fi
	sudo mkdir --parents --mode=0755 "${dirpath}"

	local -r tmp_dirpath="/tmp/${filename}"
	local -r tmp_filepath="${tmp_dirpath}/${filename}"
	local -r filepath="${dirpath}/${filename}"
	(http_download "$url" "$tmp_dirpath" "$filename" "true" &&
		sudo gpg --output "${filepath}" --dearmor "${tmp_filepath}" &&
		sudo chmod a+r "$filepath" &&
		rm --verbose --recursive --force "${tmp_dirpath}") || exit $?
}

function pkg_manager_download_add_signing_key() {
	local -r url="$1"
	local -r filename="$2"

	local -r os_id="$(os_echo_id)"
	local -r signing_key_dirpath="${___PKG_MANAGER_REPOSITORY_SIGNING_KEY_DIRPATH_BY_OS_ID[$os_id]}"
	if [ -z "$signing_key_dirpath" ]; then
		log_kill "os id '$os_id' does not have a dirpath set for signing keys"
	fi
	sudo mkdir --parents --mode=0755 "${signing_key_dirpath}"

	local -r filepath="${signing_key_dirpath}/${filename}"
	(http_download "$url" "$signing_key_dirpath" "$filename" "true" &&
		sudo chmod a+r "$filepath" || exit $?) || exit $?
}

function pkg_manager_add_signing_key() {
	local -r key="$1"
	local -r filename="$2"

	local -r os_id="$(os_echo_id)"
	local -r dirpath="${___PKG_MANAGER_REPOSITORY_SIGNING_KEY_DIRPATH_BY_OS_ID[$os_id]}"
	if [ -z "$dirpath" ]; then
		log_kill "os id '$os_id' does not have a dirpath set for signing keys"
	fi
	sudo mkdir --parents --mode=0755 "${dirpath}"

	local -r filepath="${dirpath}/${filename}"
	echo "$key" | sudo tee "$filepath" || exit $?
}

function pkg_manager_remove_signing_key() {
	local -r filename="$1"

	local -r os_id="$(os_echo_id)"
	local -r dirpath="${___PKG_MANAGER_REPOSITORY_SIGNING_KEY_DIRPATH_BY_OS_ID[$os_id]}"
	if [ -z "$dirpath" ]; then
		log_kill "os id '$os_id' does not have a dirpath set for signing keys"
	fi

	local -r filepath="${dirpath}/${filename}"
	sudo rm --verbose --recursive --force "$filepath" || exit $?
}

function pkg_manager_remove_repo() {
	local -r filename="$1"

	local -r os_id="$(os_echo_id)"
	local -r dirpath="${___PKG_MANAGER_REPOSITORY_DIRPATH_BY_OS_ID[$os_id]}"
	if [ -z "$dirpath" ]; then
		log_kill "os id '$os_id' does not have a dirpath set for signing keys"
	fi

	local -r fielpath="${dirpath}/${filename}"
	sudo rm --verbose --recursive --force "${fielpath}" || exit $?
}

function pkg_manager_add_repo() {
	local -r name="$1"
	local -r filename="$2"
	local -r url="$3"
	local -r signing_key_ref="$4"
	local -r flags="$5"

	local -r os_id="$(os_echo_id)"
	local -r repository_dirpath="${___PKG_MANAGER_REPOSITORY_DIRPATH_BY_OS_ID[$os_id]}"
	if [ -z "$repository_dirpath" ]; then
		log_kill "os id '$os_id' does not have a dirpath set for repositories" 127
	fi
	local -r filepath="${repository_dirpath}/${filename}"

	case "$os_id" in
	debian | ubuntu)
		local file_model
		file_model="#${name}\ndeb [arch=$(dpkg --print-architecture)"
		if [ -n "$signing_key_ref" ]; then
			local -r signing_key_dirpath="${___PKG_MANAGER_REPOSITORY_SIGNING_KEY_DIRPATH_BY_OS_ID[$os_id]}"
			if [ -z "$signing_key_dirpath" ]; then
				log_kill "os id '$os_id' does not have a dirpath set for signing keys"
			fi

			local -r signing_key_filepath="${signing_key_dirpath}/${signing_key_ref}"
			if [ -z "$signing_key_filepath" ]; then
				log_kill "signing key at path '$signing_key_filepath' not found"
			fi
			file_model+=" signed-by=$signing_key_filepath"
		fi
		file_model+="] $url${flags:+ ${flags}}"
		;;
	fedora)
		local file_model="[${name}]\nname=${name}\nbaseurl=${url}\nenabled=1"
		if [ -n "$signing_key_ref" ]; then
			file_model+="\ngpgcheck=1\ngpgkey=${signing_key_ref}"
		fi
		file_model+="\n${flags}"
		;;
	esac

	echo -e "$file_model" | sudo tee "$filepath" || exit $?
}
