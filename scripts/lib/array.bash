#!/usr/bin/env bash

function array_echo_concat_string() {
	local -r separator="$1"
	shift
	local -r array=("$@")

	local string=""
	local -i arr_size=${#array[@]}
	for ((i = 0; i < $arr_size; i += 1)); do
		string+="${array[$i]}"
		if [ $i -lt $((arr_size - 1)) ]; then
			string+="${separator}"
		fi
		continue
	done

	echo -n "$string"
}
