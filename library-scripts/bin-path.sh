bin_path="{{BIN_PATH}}"
if [ -n "${PATH##*${bin_path}}" ] && [ -n "${PATH##*${bin_path}:*}" ]; then
    export PATH=${bin_path}:$PATH
fi
unset bin_path
