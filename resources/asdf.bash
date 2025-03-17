#!/usr/bin/env bash

export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
export ASDF_DATA_DIR="${HOME}/.asdf"
. <(asdf completion bash)
