#!/bin/bash

set -x

# Take 3 inputs
# Add validation so that the first input should be add/update/delete
# Add validation so that the second input should be the station name
# Add validation so that the third input should be the mount point

# Assign the inputs to variables (CAPS)
ACTION=$1
STATION_NAME=$2
MOUNT_POINT=$3
ID=$(echo "${STATION_NAME}:${MOUNT_POINT}" | sha256sum -z | cut -d' ' -f1)

# This is the validation function with descriptive errors
function validate_input() {
    if [[ ${ACTION} != "add" && ${ACTION} != "update" && ${ACTION} != "delete" ]]; then
        echo "Invalid input. Please enter add/update/delete as the first argument."
        exit 1
    fi
    if [[ ${STATION_NAME} == "" ]]; then
        echo "Invalid input. Please enter the station name as the second argument."
        exit 1
    fi
    if [[ "${MOUNT_POINT}" == "" ]]; then
        echo "Invalid input. Please enter the mount point as the third argument."
        exit 1
    fi

    # Check that the station name directory exists
    if [[ ! -d /var/azuracast/stations/${STATION_NAME} ]]; then
        echo "Invalid input. The station name directory does not exist."
        mkdir -p /var/azuracast/stations/${STATION_NAME}
    fi

    # Check that the mount point exists
    if [[ ! -d /APPBOX_DATA/"${MOUNT_POINT}" ]]; then
        echo "Invalid input. The mount point directory does not exist."
        exit 1
    fi
}

# This is the add function which bind mounts the mount point to the station name directory
function add_mount() {
    # Check if the mount point is already mounted
    if [[ $(mount | grep -q "${MOUNT_POINT}") ]]; then
        echo "The mount point is already mounted."
        exit 1
    fi

    # Get the last directory name from the mount point
    MOUNT_POINT_NAME=$(basename "${MOUNT_POINT}")

    if [[ ! -d /var/azuracast/stations/${STATION_NAME}/media/${MOUNT_POINT_NAME} ]]; then
        mkdir -p /var/azuracast/stations/${STATION_NAME}/media/${MOUNT_POINT_NAME}
    fi

    chown azuracast:azuracast /var/azuracast/stations/${STATION_NAME}/media

    chown azuracast:azuracast /var/azuracast/stations/${STATION_NAME}/media/${MOUNT_POINT_NAME}

    echo "Mounting ${MOUNT_POINT} to /var/azuracast/stations/${STATION_NAME}/media/${MOUNT_POINT_NAME}"

    # Mount the mount point to the station name directory
    # Using nosuid,nodev to satisfy AppArmor mount options=(bind, nosuid, nodev)
    mount --bind -o nosuid,nodev /APPBOX_DATA/"${MOUNT_POINT}" /var/azuracast/stations/${STATION_NAME}/media/"${MOUNT_POINT_NAME}"

    # Add the mount point to the /stationmounts/mounts file in the format of "id,station_name,mount_point"
    echo "${ID},${STATION_NAME},${MOUNT_POINT}" >> /stationmounts/mounts
}

# This is the update function which unmounts the station media mount and then mounts the mount point again
function update_mount() {
    # Get the last directory name from the mount point
    MOUNT_POINT_NAME=$(basename "${MOUNT_POINT}")

    echo "Unmounting /var/azuracast/stations/${STATION_NAME}/media/${MOUNT_POINT_NAME}"

    # Unmount the station media mount
    umount /var/azuracast/stations/${STATION_NAME}/media/${MOUNT_POINT_NAME}

    echo "Mounting ${MOUNT_POINT} to /var/azuracast/stations/${STATION_NAME}/media/${MOUNT_POINT_NAME}"

    # Mount the mount point to the station name directory
    # Using nosuid,nodev to satisfy AppArmor mount options=(bind, nosuid, nodev)
    mount --bind -o nosuid,nodev /APPBOX_DATA/"${MOUNT_POINT}" /var/azuracast/stations/${STATION_NAME}/media/"${MOUNT_POINT_NAME}"

    # Update /stationmounts/mounts
    sed -i "s|${ID},.*|${ID},${STATION_NAME},${MOUNT_POINT}|" /stationmounts/mounts
}

# This is the delete function which unmounts the station media mount
function delete_mount() {
    # Get the last directory name from the mount point
    MOUNT_POINT_NAME=$(basename "${MOUNT_POINT}")

    echo "Unmounting /var/azuracast/stations/${STATION_NAME}/media/${MOUNT_POINT_NAME}"

    # Delete the mount point from the /stationmounts/mounts file
    sed -i "/${ID}/d" /stationmounts/mounts

    # Add the mount point to the /stationmounts/mounts file in the format of "id,station_name,mount_point,delete_me"
    echo "${ID},${STATION_NAME},${MOUNT_POINT},delete_me" >> /stationmounts/mounts

    echo "Restating container to clear mounts"

    pkill -9 supervisord
}

# This is the main function which calls the validation function and then the add/update/delete function
function main() {
    validate_input

    if [[ ${ACTION} == "add" ]]; then
        add_mount
    elif [[ ${ACTION} == "update" ]]; then
        update_mount
    elif [[ ${ACTION} == "delete" ]]; then
        delete_mount
    fi
}

main