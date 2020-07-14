#!/bin/bash
set -e

# Determine my current dir (src: https://stackoverflow.com/a/246128/13519872).
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

echo "My dir: $DIR"

# Load config.
. $DIR/config.cfg

# Handle args.
if [ $# -eq 0 ]; then
        echo "Usage: $0 <source_path>"
        exit 1
fi

# Essentials.
readarray -d '/' -t remote_mount_path_arr < <( echo "$remote_mount_path"  )
source_path="$1"
readarray -d '/' -t source_path_arr < <( echo "$source_path"  )
source_dir="${source_path_arr[-1]}"
dialog=$(which $dialog_util)
rclone=$(which rclone)
dialog_title="Upload with RClone..."

echo "source path: $source_path"
echo "source dir: $source_dir"

# Get list of remotes.
readarray -t remotes < <( $rclone listremotes )

# Prepend a '^' to the default remote item for YAD to recognise it as the default option.
for remote in "${remotes[@]}"
do
    if [ "$remote" == "$default_remote" ]; then
        echo "${remotes[$i]} --> ^$remote"
        remotes[$i]="^$remote"
    fi
    
    # Increment loop counter.
    i=$((i + 1))
done

# Transform array items into a string, separated by pipes.
remotes_str=$( printf '%s!' "${remotes[@]}" )
# Strip the trailing pipe separator.
remotes_str=${remotes_str%?}
echo "Remotes: $remotes_str)"

echo "Launching dialog 1..."
dialog1=$( \
    $dialog --title "$dialog_title" --form --center \
        --field="Remote   ":CB "$remotes_str" \
        --field="Transfers":NUM 12 \
        --field="Destination directory":DIR \
        --field="RClone options:":LBL \
        --field="Don't be verbose":CHK \
        --field="RClone Copy options:":LBL \
        --field="Don't show progress":CHK \
        --field="Don't include dir":CHK \
        --field="Dry run":CHK \
        --field="Script options:":LBL \
        --field="Don't run via SSH (FIXME: Implement!)":CHK \
        )

echo "dialog1: $dialog1"

# Determine selected input from returned list.
readarray -d '|' -t dialog1_arr < <( echo "$dialog1"  )


# Set variables for selection.
sel_remote=${dialog1_arr[0]}
sel_transfers=${dialog1_arr[1]}
sel_dest=${dialog1_arr[2]}
# Label field on index 3
sel_rclone_opt_noverbose=${dialog1_arr[4]}
# Label field on index 5
sel_rclone_copy_opt_noprogress=${dialog1_arr[6]}
sel_rclone_copy_opt_nodir=${dialog1_arr[7]}
sel_rclone_copy_opt_dryrun=${dialog1_arr[8]}
# Label field on index 9
sel_opt_nossh=${dialog1_arr[10]}

echo "Selection:"
echo -e "\tRemote:       $sel_remote"
echo -e "\tTransfers:    $sel_transfers"
echo -e "\tDestination:  $sel_dest"
echo -e "\tNOT Verbose:  $sel_rclone_opt_noverbose"
echo -e "\tNOT Progress: $sel_rclone_copy_opt_noprogress"
echo -e "\tNOT incl dir: $sel_rclone_copy_opt_nodir"
echo -e "\tNOT SSH:      $sel_opt_nossh"
echo ""

# Compile opts strings.
rclone_opts=""
rclone_copy_opts=""
script_opts=""
if [ "$sel_rclone_opt_noverbose" != "TRUE" ]; then
    rclone_opts="$rclone_opts -v"
fi
if [ "$sel_rclone_copy_opt_noprogress" != "TRUE" ]; then
    rclone_copy_opts="$rclone_copy_opts --progress"
fi
if [ "$sel_rclone_copy_opt_dryrun" == "TRUE" ]; then
    rclone_copy_opts="$rclone_copy_opts -n"
fi


# Perform a sanity check that dest is in fact inside the rclone mount path.
if [[ "$sel_dest" != "$remote_mount_path"* ]]; then
    error_msg="Destination path does not start with RClone mount path!\n\nMount: $remote_mount_path\nDest: $sel_dest"
    echo -e "Error: $error_msg"
    $dialog --image dialog-error --center --title "Error" --text "$error_msg"
    exit 1
fi

# Replace start of dest with the corresponding remote path:
# 1. Replace all '/' with "\/" to make it regex safe.
rem_mnt_regexsafe=$(echo "$remote_mount_path" | sed -e 's/\//\\\//g')
# 2. Use the regex-safe string in the substitution expression.
remote_dest_path=$( echo "$sel_dest" | sed -e "s/$rem_mnt_regexsafe/$sel_remote/" )

# Make any final adjustments to the remote dest path:
# Handle inclusion of source dir (if not included, rclone will copy contents, not dir itself)
if [ "$sel_rclone_copy_opt_nodir" != "TRUE" ]; then
    # Use echo to filter out strange junk data that sometimes occurs.
    remote_dest_path=$(echo "$remote_dest_path/$source_dir")
fi

echo "Remote dest path: $remote_dest_path"

# Finally spawn a terminal with the rclone copy process!
title="RClone copy: $source_path --> $remote_dest_path"
echo "rclone cmd: $rclone $rclone_opts copy $rclone_copy_opts --transfers=$sel_transfers "$source_path" "$remote_dest_path""
exec $terminal $terminal_opts $terminal_title_opt "$title" $terminal_run_cmd_opt $rclone $rclone_opts copy $rclone_copy_opts --transfers=$sel_transfers "$source_path" "$remote_dest_path"