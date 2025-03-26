#!/usr/bin/env bash

source "scripts/lib/os.bash"
source "scripts/lib/http.bash"
source "scripts/lib/pkg_manager.bash"
source "scripts/lib/git.bash"

declare -r NERD_FONTS_REPOSITORY_URL="https://github.com/ryanoasis/nerd-fonts"
declare -r NERD_FONTS_DOWNLOAD_RAW_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/@{{version_tag}}/@{{font_name}}.tar.xz"

declare -r NERD_FONTS_DOWNLOAD_DIRPATH="/tmp/nerd-fonts"
declare -r NERD_FONTS_INSTALL_DIRPATHS=("${HOME}/.local/share/fonts" "${HOME}/.fonts")
declare -ra NERD_FONTS_FONT_NAMES=(
	"0xProto"
	"AnonymousPro"
	"CommitMono"
	"D2Coding"
	"FantasqueSansMono"
	"GeistMono"
	"Inconsolata"
	"IntelOneMono"
	"Iosevka"
	"IosevkaTerm"
	"Monoid"
	"Mononoki"
	"Noto"
	"Recursive"
	"RobotoMono"
	"NerdFontsSymbolsOnly"
)

function script_program_install() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | void | alpine | debian | ubuntu | fedora)
		local -r version_tag="$(git_echo_latest_tag "$NERD_FONTS_REPOSITORY_URL")"

		local -r versioned_url="${NERD_FONTS_DOWNLOAD_RAW_URL//\@\{\{version_tag\}\}/${version_tag}}"
		echo "$versioned_url"
		for font_name in "${NERD_FONTS_FONT_NAMES[@]}"; do
			local download_url="${versioned_url//\@\{\{font_name\}\}/${font_name}}"
			local font_filename="${font_name}.tar.xz"
			http_download "$download_url" "$NERD_FONTS_DOWNLOAD_DIRPATH" "$font_filename"

			local font_filepath="${NERD_FONTS_DOWNLOAD_DIRPATH}/${font_filename}"

			for install_dirpath in "${NERD_FONTS_INSTALL_DIRPATHS[@]}"; do
				local install_font_dirpath="${install_dirpath}/${font_name}"
				mkdir --parents "${install_font_dirpath}" || exit $?
				tar --verbose --extract --file="$font_filepath" --directory="$install_font_dirpath" || exit $?
			done
		done
		sudo fc-cache --verbose --force --really-force
		rm --verbose --recursive --force "${NERD_FONTS_DOWNLOAD_DIRPATH}"
		;;
	esac
}

function script_program_uninstall() {
	local -r os_id="$(os_echo_id)"
	case "$os_id" in
	arch | void | alpine | debian | ubuntu | fedora)
		for font_name in "${NERD_FONTS_FONT_NAMES[@]}"; do
			for install_dirpath in "${NERD_FONTS_INSTALL_DIRPATHS[@]}"; do
				local install_font_dirpath="${install_dirpath}/${font_name}"
				rm --verbose --recursive --force "${install_font_dirpath}" || exit $?
			done
		done
		sudo fc-cache --verbose --force --really-force
		;;
	esac
}

source "scripts/ext/program_menu.bash"
