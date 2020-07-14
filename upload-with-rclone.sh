#!/bin/bash

# Handle args.
if [ $# -eq 0 ]; then
        echo "Usage: $0 <source_path>"
        exit 1
fi

# FIXME: Config opts.
default_remote="tohru:"
remote_mount_path="/tohru/"
dialog_util=$(which yad)
terminal=$(which konsole)
terminal_title_opt="--title"
terminal_run_cmd_opt="-e"
terminal_opts="--separate --hide-menubar --hide-tabbar --noclose" 

# Essentials.
source_path="$1"
readarray -d '/' -t remote_mount_path_arr < <( echo "$remote_mount_path"  )
dialog=$(which $dialog_util)
rclone=$(which rclone)
dialog_title="Upload with RClone..."

echo "source path: $source_path"

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
        --field="Don't include dir (FIXME: Implement!)":CHK \
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
# Label field on index 8
sel_opt_nossh=${dialog1_arr[9]}

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

echo "Remote dest path: $remote_dest_path"

# Finally spawn a terminal with the rclone copy process!
title="RClone copy: $source_path --> $remote_dest_path"
exec $terminal $terminal_opts $terminal_title_opt "$title" $terminal_run_cmd_opt $rclone $rclone_opts copy $rclone_copy_opts --transfers=$sel_transfers "$source_path" "$remote_dest_path"