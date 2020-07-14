# Upload with RClone (ServiceMenu utillity)
Adds a context menu action to upload the selected directory to an rclone remote.

## Install
Copy or hard/symlink `upload-with-rclone.desktop` and `upload-with-rclone.sh` to `$HOME/.local/share/kservices5/ServiceMenus/` (You might need to create some of the directories).

## Usage
Right-click on a folder in e.g. dolphin and click `Upload with RClone...` which should be under the `Actions` menu.

## Requirements
 * yad
 * rclone
 * A reasonably modern version of BASH