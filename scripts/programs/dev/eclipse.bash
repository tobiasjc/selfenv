#!/usr/bin/env bash

source "scripts/lib/pkg_manager.bash"
source "scripts/lib/os.bash"
source "scripts/lib/http.bash"
source "scripts/lib/checksum.bash"
source "scripts/lib/installer.bash"

declare -r ECLIPSE_PROGRAM_NAME="eclipse"

declare -rai ECLIPSE_ICON_SIZES=(16 24 32 48 64 128 256)
declare -r ECLIPSE_ICON_NAME_PREFIX="eclipse"
declare -r ECLIPSE_DESKTOP_FILENAME_PREFIX="epp.package"
declare -ra ECLIPSE_PKGS=("jee" "cpp" "php")
declare -r ECLIPSE_INSTALL_DIR="${HOME}/.${ECLIPSE_PROGRAM_NAME}"

function ___eclipse_install_dependencies() {
	./run.bash --program htmlq --install
}

function script_program_install() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | void | alpine | debian | ubuntu | fedora)
		___eclipse_install_dependencies

		# 1. versioning
		local -r version_page_url="https://www.eclipse.org/downloads/packages/release"
		local -r version="$(wget --quiet --output-document=- "$version_page_url" |
			htmlq --text "section#block-system-main div.block-content > ul > li.first" |
			tr --delete '[:cntrl:]')"
		local -r architecture="$(os_echo_machine_architecture)"
		local -r download_output_dirpath="/tmp/${ECLIPSE_PROGRAM_NAME}"

		for package in "${ECLIPSE_PKGS[@]}"; do
			# 2. download
			local download_url="https://download.eclipse.org/technology/epp/downloads/release/${version}/R/eclipse-${package}-${version}-R-linux-gtk-${architecture}.tar.gz"
			local download_filename="${package}-${version}.tar.gz"
			local download_filepath="${download_output_dirpath}/${download_filename}"
			http_download "$download_url" "$download_output_dirpath" "$download_filename"

			local download_md5_filename="${download_filename}.md5"
			local download_md5_url="${download_url}.md5"
			local download_md5_filepath="${download_output_dirpath}/${download_md5_filename}"
			http_download "$download_md5_url" "$download_output_dirpath" "$download_md5_filename"

			# 3. checksum
			(checksum_md5_file "$download_filepath" "$download_md5_filepath") || exit $?

			# 4. install
			local install_path="${ECLIPSE_INSTALL_DIR}/${package}-${version}"
			local install_bin_name="${ECLIPSE_PROGRAM_NAME}-${package}"
			(tar --verbose --extract --directory="$download_output_dirpath" --file="$download_filepath" &&
				mkdir --verbose --parents "${ECLIPSE_INSTALL_DIR}" &&
				rm --verbose --recursive --force "$install_path" &&
				mv --verbose --force "${download_output_dirpath}/${ECLIPSE_PROGRAM_NAME}" "$install_path") || exit $?
			installer_install_link_bin_local "${install_path}/${ECLIPSE_PROGRAM_NAME}" "$install_bin_name"

			local icon_name="${ECLIPSE_ICON_NAME_PREFIX}-${package}"
			local icon_extension="xpm"
			for icon_size in "${ECLIPSE_ICON_SIZES[@]}"; do
				installer_install_link_icon_local "${install_path}/icon.xpm" "${icon_name}.${icon_extension}" "$icon_size"
			done

			installer_install_desktop_file_local "${ECLIPSE_DESKTOP_FILENAME_PREFIX}.${package}" --set-name="${ECLIPSE_PROGRAM_NAME}-${package}" \
				--set-key="Type" --set-value="Application" \
				--set-key="Exec" --set-value="${install_bin_name} %u" \
				--set-icon="${icon_name}" \
				--add-category="Development" --add-category="IDE" --add-category="X-Eclipse"
		done

		# 5. clear
		rm --verbose --recursive --force "$download_output_dirpath"
		;;
	esac
}

function script_program_uninstall() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | void | alpine | debian | ubuntu | fedora)
		for package in "${ECLIPSE_PKGS[@]}"; do
			installer_uninstall_bin_local "${ECLIPSE_PROGRAM_NAME}-${package}"
			for icon_size in "${ECLIPSE_ICON_SIZES[@]}"; do
				installer_uninstall_icon_local "${ECLIPSE_ICON_NAME_PREFIX}-${package}.xpm" "$icon_size"
			done

			(rm --verbose --recursive --force "${ECLIPSE_INSTALL_DIR:?}/${package:?}"* &&
				installer_uninstall_desktop_file_local "${ECLIPSE_DESKTOP_FILENAME_PREFIX}.${package}.desktop") || exit $?
		done
		(rm --verbose --recursive --force "${ECLIPSE_INSTALL_DIR}") || exit $?
		;;
	esac
}

source "scripts/ext/program_menu.bash"
