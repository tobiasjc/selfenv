#!/usr/bin/env bash

source "scripts/lib/log.bash"

function md5_check_hash_file() {
	local -r filepath="$1"
	local -r hash_filepath="$2"

	local -r file_md5="$(md5sum "$filepath" |
		cut --delimiter=' ' --fields=1 |
		tr --delete '[:cntrl:]' |
		tr --delete '[:punct:]')"
	local -r hash_file_md5="$(cut --delimiter=' ' --fields=1 <"$hash_filepath" |
		tr --delete '[:cntrl:]' |
		tr --delete '[:punct:]')"

	if [ "$file_md5" != "$hash_file_md5" ]; then
		log_kill "file '$filepath' md5 '$file_md5', and file '$hash_filepath' md5 '$hash_file_md5' are not equal" 127
		exit 1
	fi
}
