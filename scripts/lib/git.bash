#!/usr/bin/env bash

source "scripts/lib/file.bash"

function git_clone() {
	local -r repo_url="$1"
	local -r branch="$2"
	local -r target_dir="$3"
	local -r opts="$4"
	local -r force="${5:-true}"
	local -r sudo="${6:-false}"

	file_verify_not_exists "$target_dir" "$force"

	local cmd="git clone --verbose ${opts} ${repo_url}"
	if [ "$sudo" = "true" ]; then
		cmd="sudo ${cmd}"
	fi

	if [ "$branch" = "latest" ]; then
		cmd+=" --branch=$(git_echo_latest_tag "$repo_url")"
	elif [ -n "$branch" ]; then
		cmd+=" --branch=${branch}"
	fi
	cmd+=" ${target_dir}"

	(eval "$cmd") || exit $?
}

function git_echo_all_tags() {
	local -r repo_url="$1"
	local -r all_tags="$(git ls-remote --tags --no-refs --no-server-option --no-upload-pack --sort='version:refname' "$repo_url" |
		cut -f2 |
		sed -e 's/refs\/tags\///g' |
		sed -E 's/\^[{](.*?)[}]//g' |
		tac)"
	echo "$all_tags"
}

function git_echo_latest_tag() {
	local -r repo_url="$1"
	local -r pattern="$2"

	local latest_tag=""
	local -r all_tags="$(git_echo_all_tags "$repo_url")"
	if [ -n "$pattern" ]; then
		for tag in $all_tags; do
			if [[ "$tag" =~ $pattern ]]; then
				latest_tag="$tag"
				break
			fi
		done
	else
		latest_tag="$(echo "$all_tags" | head -n1)"
	fi
	echo "$latest_tag"
}
