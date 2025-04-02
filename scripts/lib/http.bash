#!/usr/bin/env bash

declare -A DOWNLOADERS_TO_OPTIONS=(
	["aria2c"]="\${___http_download_url} --auto-file-renaming=false --allow-overwrite=true --dir=\${___http_download_dirpath} --out=\${___http_download_filename}"
	["wget"]="\${___http_download_url} --output-document=\${___http_download_dirpath}/\${___http_download_filename}"
	["curl"]="\${___http_download_url} --verbose --location --create-dirs --output \${___http_download_dirpath}/\${___http_download_filename}"
)

function http_download() {
	local -r ___http_download_url="$1"
	local -r ___http_download_dirpath="$2"
	local -r ___http_download_filename="$3"
	local -r sudo="${4:-false}"

	for downloader in "${!DOWNLOADERS_TO_OPTIONS[@]}"; do
		if which "$downloader"; then
			if [ ! -e "$___http_download_dirpath" ]; then
				mkdir --parents "$___http_download_dirpath" || exit $?
			fi

			local -r ops="${DOWNLOADERS_TO_OPTIONS[$downloader]}"
			local cmd+="$downloader $ops"
			if [ "$sudo" = "true" ]; then
				cmd="sudo $cmd"
			fi
			eval "$cmd" || exit $?
			return 0
		fi
	done

	exit 1
}
