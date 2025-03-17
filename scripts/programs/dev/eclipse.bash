#!/usr/bin/env bash

source "scripts/lib/pkg_manager.bash"
source "scripts/lib/os.bash"
source "scripts/lib/http.bash"
source "scripts/lib/file.bash"
source "scripts/lib/md5.bash"

declare -r ECLIPSE_PROGRAM_NAME="eclipse"
declare -r ECLIPSE_RELEASES_PAGE_URL="https://www.eclipse.org/downloads/packages/release"
declare -r ECLIPSE_RELEASES_SELECTOR="section#block-system-main div.block-content > ul > li.first"

declare -r ECLIPSE_DESKTOP_FILENAME_PREFIX="epp.package"

declare -r ECLIPSE_DOWNLOAD_OUTPUT_DIR="/tmp/${ECLIPSE_PROGRAM_NAME}"
declare -r ECLIPSE_DOWNLOAD_RAW_URL="https://download.eclipse.org/technology/epp/downloads/release/@{{version}}/R/eclipse-@{{package}}-@{{version}}-R-linux-gtk-@{{architecture}}.tar.gz"

declare -rA ECLIPSE_INSTALL_PACKAGE_TO_DESCRIPTION=(
	["jee"]="Eclipse IDE for Enterprise Java and Web Developers"
	["cpp"]="Eclipse IDE for C/C++ Developers"
	["php"]="Eclipse IDE for PHP Developers"
	["modeling"]="Eclipse Modeling Tools"
)

declare -r ECLIPSE_INSTALL_DIR="${HOME}/.${ECLIPSE_PROGRAM_NAME}"

function script_program_install() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | void | alpine | debian | ubuntu | rhel | fedora)
		(source "scripts/programs/qol/htmlq.bash" && script_program_install) || exit $?
		local -r version="$(wget --quiet --output-document=- "$ECLIPSE_RELEASES_PAGE_URL" |
			htmlq --text "$ECLIPSE_RELEASES_SELECTOR" |
			tr --delete '[:cntrl:]')"
		local -r architecture="$(os_echo_machine_architecture)"
		local -r base_download_url="$(echo -n "$ECLIPSE_DOWNLOAD_RAW_URL" |
			sed -e "s/@{{version}}/$version/g" |
			sed -e "s/@{{architecture}}/$architecture/g")"

		(rm --verbose --recursive --force "$ECLIPSE_DOWNLOAD_OUTPUT_DIR") || exit $?
		for package in "${!ECLIPSE_INSTALL_PACKAGE_TO_DESCRIPTION[@]}"; do
			# 1. download
			local download_filename="${package}-${version}.tar.gz"
			local download_filepath="${ECLIPSE_DOWNLOAD_OUTPUT_DIR}/${download_filename}"
			local download_url="$(echo -n "$base_download_url" |
				sed -e "s/@{{package}}/$package/g")"
			http_download "$download_url" "$ECLIPSE_DOWNLOAD_OUTPUT_DIR" "$download_filename"

			local download_md5_filename="${download_filename}.md5"
			local download_md5_url="${download_url}.md5"
			local download_md5_filepath="${ECLIPSE_DOWNLOAD_OUTPUT_DIR}/${download_md5_filename}"
			http_download "$download_md5_url" "$ECLIPSE_DOWNLOAD_OUTPUT_DIR" "$download_md5_filename"

			# 2. checksum md5
			(md5_check_hash_file "$download_filepath" "$download_md5_filepath") || exit $?

			# 3. install
			local download_filepath="${ECLIPSE_DOWNLOAD_OUTPUT_DIR}/${download_filename}"
			local install_path="${ECLIPSE_INSTALL_DIR}/${package}-${version}"
			(tar --verbose --extract --directory="$ECLIPSE_DOWNLOAD_OUTPUT_DIR" --file="$download_filepath" &&
				mkdir --verbose --parents "${ECLIPSE_INSTALL_DIR}" &&
				rm --verbose --recursive --force "$install_path" &&
				mv --verbose --force "${ECLIPSE_DOWNLOAD_OUTPUT_DIR}/${ECLIPSE_PROGRAM_NAME}" "${install_path}") || exit $?

			# 4. create desktop entry
			local description="${ECLIPSE_INSTALL_PACKAGE_TO_DESCRIPTION[${package}]}"
			local exec_path="${install_path}/${ECLIPSE_PROGRAM_NAME}"
			local icon_path="${install_path}/icon.xpm"
			local desktop_file_content
			desktop_file_content="$(sed -e "s|@{{name}}|${ECLIPSE_PROGRAM_NAME}-${package}|g" "resources/application-eclipse.desktop" |
				sed -e "s|@{{comment}}|${description}|g" |
				sed -e "s|@{{icon_path}}|${icon_path}|g" |
				sed -e "s|@{{exec_path}}|${exec_path}|g")"

			local desktop_filename="${ECLIPSE_DESKTOP_FILENAME_PREFIX}.${package}.desktop"
			file_application_local_install "$desktop_filename" "$desktop_file_content"
		done
		rm --verbose --recursive --force "$ECLIPSE_DOWNLOAD_OUTPUT_DIR"
		;;
	esac
}

function script_program_uninstall() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | void | alpine | debian | ubuntu | rhel | fedora)
		for package in "${!ECLIPSE_INSTALL_PACKAGE_TO_DESCRIPTION[@]}"; do
			local desktop_filename="${ECLIPSE_DESKTOP_FILENAME_PREFIX}.${package}.desktop"
			(rm --verbose --recursive --force "${ECLIPSE_INSTALL_DIR:?}/${package:?}"* &&
				file_application_local_uninstall "$desktop_filename") || continue
		done
		;;
	esac
}

source "scripts/ext/program_menu.bash"
