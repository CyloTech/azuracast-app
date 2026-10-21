#!/bin/bash

# Create required socket directories for services
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

mkdir -p /run/redis
chown -R valkey:valkey /run/redis

cat << EOF > /var/azuracast/www/.env
AZURACAST_STATION_PORTS=${AZURACAST_STATION_PORTS}
AZURACAST_SFTP_PORT=${AZURACAST_SFTP_PORT}
LANG=${LANG}
AZURACAST_DC_REVISION=${AZURACAST_DC_REVISION}
AZURACAST_VERSION=${AZURACAST_VERSION}
NGINX_TIMEOUT=${NGINX_TIMEOUT}
PUID=${PUID}
PGID=${PGID}
INIT_BASE_URL=${INIT_BASE_URL}
MARIADB_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD}
INIT_ADMIN_EMAIL=${INIT_ADMIN_EMAIL}
INIT_ADMIN_PASSWORD=${INIT_ADMIN_PASSWORD}
INIT_INSTANCE_NAME=${INIT_INSTANCE_NAME}
AUTO_ASSIGN_PORT_MIN=${AUTO_ASSIGN_PORT_MIN}
AUTO_ASSIGN_PORT_MAX=${AUTO_ASSIGN_PORT_MAX}
AZURACAST_BASE_URL=${INIT_BASE_URL}
APPLICATION_ENV=production
PHP_MEMORY_LIMIT=3072M
EOF

cat << EOF > /var/azuracast/www/azuracast.env
AZURACAST_STATION_PORTS=${AZURACAST_STATION_PORTS}
AZURACAST_SFTP_PORT=${AZURACAST_SFTP_PORT}
LANG=${LANG}
AZURACAST_DC_REVISION=${AZURACAST_DC_REVISION}
AZURACAST_VERSION=${AZURACAST_VERSION}
NGINX_TIMEOUT=${NGINX_TIMEOUT}
PUID=${PUID}
PGID=${PGID}
INIT_BASE_URL=${INIT_BASE_URL}
MARIADB_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD}
INIT_ADMIN_EMAIL=${INIT_ADMIN_EMAIL}
INIT_ADMIN_PASSWORD=${INIT_ADMIN_PASSWORD}
INIT_INSTANCE_NAME=${INIT_INSTANCE_NAME}
AUTO_ASSIGN_PORT_MIN=${AUTO_ASSIGN_PORT_MIN}
AUTO_ASSIGN_PORT_MAX=${AUTO_ASSIGN_PORT_MAX}
AZURACAST_BASE_URL=${INIT_BASE_URL}
APPLICATION_ENV=production
PHP_MEMORY_LIMIT=3072M
EOF

chown -R azuracast:azuracast /var/azuracast/www/.env
chown -R azuracast:azuracast /var/azuracast/www/azuracast.env

touch /stationmounts/mounts

grep ',delete_me$' /stationmounts/mounts | while read -r MOUNT_LINE
do
    STATION_NAME=$(echo $MOUNT_LINE | cut -d',' -f2)
    MOUNT_POINT=$(echo $MOUNT_LINE | cut -d',' -f3)
    MOUNT_ID=$(echo "${STATION_NAME}:${MOUNT_POINT}" | sha256sum -z | cut -d' ' -f1)
    MOUNT_POINT_NAME=$(basename "${MOUNT_POINT}")
    MOUNT_PATH="/var/azuracast/stations/${STATION_NAME}/media/${MOUNT_POINT_NAME}"

    echo "Unmounting ID ${MOUNT_ID}, ${STATION_NAME} at ${MOUNT_PATH}"
    umount "${MOUNT_PATH}"

    # Check if the mount point is empty
    if [ "$(ls -A ${MOUNT_PATH})" ]; then
        echo "Mount point ${MOUNT_PATH} is not empty, not deleting"
        # Delete matching line from /stationmounts/mounts
        sed -i "/${MOUNT_ID}/d" /stationmounts/mounts
        continue
    fi

    echo "Deleting ID ${MOUNT_ID}, ${STATION_NAME} at ${MOUNT_PATH}"
    rm -r "${MOUNT_PATH}"
    sed -i "/${MOUNT_ID}/d" /stationmounts/mounts
done

# mount from the /stationmounts/mounts file in the format of "id,station_name,mount_point"
while read -r MOUNT_LINE
do
    STATION_NAME=$(echo $MOUNT_LINE | cut -d',' -f2)
    MOUNT_POINT=$(echo $MOUNT_LINE | cut -d',' -f3)
    MOUNT_ID=$(echo "${STATION_NAME}:${MOUNT_POINT}" | sha256sum -z | cut -d' ' -f1)
    MOUNT_POINT_NAME=$(basename "${MOUNT_POINT}")
    MOUNT_PATH="/var/azuracast/stations/${STATION_NAME}/media/${MOUNT_POINT_NAME}"

    echo "Unmounting ID ${MOUNT_ID}, ${STATION_NAME} at ${MOUNT_PATH}"
    umount "${MOUNT_PATH}"

    mkdir -p $MOUNT_PATH
    chown -R azuracast:azuracast $MOUNT_PATH
    chmod -R 775 $MOUNT_PATH
    echo "Mounting ID ${MOUNT_ID}, ${STATION_NAME} at ${MOUNT_PATH}"
    mount --bind /APPBOX_DATA/"${MOUNT_POINT}" "${MOUNT_PATH}"
done < <(cat /stationmounts/mounts)