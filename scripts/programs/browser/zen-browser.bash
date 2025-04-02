#!/usr/bin/env bash

source "scripts/lib/pkg_manager.bash"
source "scripts/lib/git.bash"
source "scripts/lib/http.bash"
source "scripts/lib/os.bash"
source "scripts/lib/installer.bash"

declare -r ZEN_BROwSER_BIN_NAME="zen-browser"
declare -r ZEN_BROWSER_INSTALL_DIRPATH="/opt/zen-browser"

declare -r ZEN_BROWSER_ICON_NAME="zen"
declare -r ZEN_BROWSER_ICON_EXTENSION="png"
declare -ra ZEN_BROWSER_ICON_SIZES=(16 32 48 64 128)

declare -r ZEN_BROWSER_DESKTOP_FILENAME="zen.desktop"

declare -ra ZEN_BROWSER_PKG_BY_OS_ID=(
	["arch"]="zen-browser-bin"
)

declare -r ZEN_BROWSER_GITHUB_URL="https://github.com/zen-browser/desktop"
declare -r ZEN_BROWSER_DOWNLOAD_URL_RAW="https://github.com/zen-browser/desktop/releases/download/@{{version_tag}}/zen.@{{kernel_name}}-@{{machine_architecture}}.tar.xz"

function script_program_install() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch)
		local -r pkg_name="${ZEN_BROWSER_PKG_BY_OS_ID[$os_id]}"
		pkg_manager_install "$pkg_name"
		;;
	alpine | debian | ubuntu | fedora)
		# 1. download
		local -r version_tag="$(git_echo_latest_tag "$ZEN_BROWSER_GITHUB_URL" '--sort=version:refname' '^[0-9]+\.[0-9]+b$')"
		echo "$version_tag"
		local -r machine_architecture="$(os_echo_machine_architecture)"
		local -r kernel_name="$(os_echo_kernel_name)"
		local -r download_url="$(echo "$ZEN_BROWSER_DOWNLOAD_URL_RAW" |
			sed -e "s/@{{version_tag}}/$version_tag/g" |
			sed -e "s/@{{kernel_name}}/$kernel_name/g" |
			sed -e "s/@{{machine_architecture}}/$machine_architecture/g")"

		local -r download_dirpath="/tmp/zen-browser"
		local -r download_filename="zen-browser.tar.xz"
		http_download "$download_url" "$download_dirpath" "$download_filename"

		# 2. install
		local -r download_filepath="${download_dirpath}/${download_filename}"
		(sudo mkdir --parents "$ZEN_BROWSER_INSTALL_DIRPATH" &&
			sudo tar --verbose --extract --strip-components=1 --file="${download_filepath}" --directory="$ZEN_BROWSER_INSTALL_DIRPATH" &&
			installer_install_global_link_bin "${ZEN_BROWSER_INSTALL_DIRPATH}/zen" "$ZEN_BROwSER_BIN_NAME" &&
			sudo ln -Ts /usr/share/hunspell "${ZEN_BROWSER_INSTALL_DIRPATH}/dictionaries" &&
			sudo ln -Ts /usr/share/hyphen "${ZEN_BROWSER_INSTALL_DIRPATH}/hyphenation") || exit $?

		# 3. install icons
		local -r icons_dirpath="${ZEN_BROWSER_INSTALL_DIRPATH}/browser/chrome/icons/default"
		for size in "${ZEN_BROWSER_ICON_SIZES[@]}"; do
			installer_install_link_icon_global "${icons_dirpath}/default${size}.${ZEN_BROWSER_ICON_EXTENSION}" "${ZEN_BROWSER_ICON_NAME}.${ZEN_BROWSER_ICON_EXTENSION}" "$size"
		done

		# 4. install desktop file
		local -r git_repo_clone_dirpath="/tmp/zen-browser-repo"
		git_clone "$ZEN_BROWSER_GITHUB_URL" "$version_tag" "$git_repo_clone_dirpath" "--depth=1"

		installer_install_desktop_file_from_filepath_global "${git_repo_clone_dirpath}/AppDir/${ZEN_BROWSER_DESKTOP_FILENAME}" \
			--set-name="Zen Browser" \
			--set-key="Exec" --set-value="/usr/bin/${ZEN_BROwSER_BIN_NAME} %u" \
			--set-icon="$ZEN_BROWSER_ICON_NAME" \
			--add-category="Network" --add-category="WebBrowser"

		# 5. clean
		(rm --verbose --recursive --force "$download_dirpath" "$git_repo_clone_dirpath") || exit $?
		;;
	esac
}

function script_program_uninstall() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch)
		pkg_manager_uninstall "${ZEN_BROWSER_PKG_BY_OS_ID[$os_id]}"
		;;
	alpine | debian | ubuntu | fedora)
		(sudo rm --verbose --recursive --force "${ZEN_BROWSER_INSTALL_DIRPATH}") || exit $?
		installer_uninstall_bin_global "$ZEN_BROwSER_BIN_NAME"
		for size in "${ZEN_BROWSER_ICON_SIZES[@]}"; do
			installer_uninstall_icon_global "${ZEN_BROWSER_ICON_NAME}.${ZEN_BROWSER_ICON_EXTENSION}" "$size"
		done
		installer_uninstall_desktop_file_global "$ZEN_BROWSER_DESKTOP_FILENAME"
		;;
	esac
}

source "scripts/ext/program_menu.bash"
