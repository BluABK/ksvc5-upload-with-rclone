#!/bin/bash

# FIXME: Config opts.
default_remote="tohru:"
dialog_util=$(which yad)

# Essentials.
dialog=$(which $dialog_util)
rclone=$(which rclone)
dialog_title="Upload with RClone..."

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

# dialog1_cmd="$dialog --title \"$dialog_title\" --form --center --field='Remote':CB \"$remotes_str\" --field='Transfers':NUM 12"
echo "Launching dialog 1..."
dialog1=$( \
    $dialog --title "$dialog_title" --form --center \
        --field="Remote   ":CB "$remotes_str" \
        --field="Transfers":NUM 12 \
        )

# dialog1=$("$dialog1_cmd")
# echo "dialog cmd: $dialog1_cmd"

# echo "$dialog --title "$dialog_title" --form --center \
#         --field="Remote   ":CB "$remotes_str" \
#         --field="Transfers":NUM 12\
#     )"

echo "dialog1: $dialog1"

# Determine selected input from returned list.
readarray -d '|' -t dialog1_arr < <( echo "$dialog1"  )

# Set variables for selection.
sel_remote=${dialog1_arr[0]}
sel_transfers=${dialog1_arr[1]}

# if [${dialog1[0]} != '']; then
#     selected_remote=${dialog1[0]}
# else
#     selected_remote=$default_remote
# fi

echo "Selection:"
echo -e "\tRemote:    $sel_remote"
echo -e "\tTransfers: $sel_transfers"