# Build PATH from the shared list so Nushell, Bash, and Zsh use the same order.
_path_file="$HOME/dotfiles/shell/path.dirs"
_path_value=

while IFS= read -r _path_entry || [ -n "$_path_entry" ]; do
    case "$_path_entry" in
        ''|\#*) continue ;;
        @/*) _path_entry="$HOME/${_path_entry#@/}" ;;
    esac

    if [ -z "$_path_value" ]; then
        _path_value="$_path_entry"
    else
        _path_value="$_path_value:$_path_entry"
    fi
done < "$_path_file"

PATH="$_path_value"
export PATH
unset _path_file _path_value _path_entry
