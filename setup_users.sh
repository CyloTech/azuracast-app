#!/bin/bash

if [[ ! -f /stationmounts/.installed ]]; then
    php /var/azuracast/www/backend/bin/uptime_wait

    # Fix for the error, not sure why this is happening, but it's a workaround to copy the error.mp3 file to the tmp directory
    # 09:33:57 ERROR     [AzuraCast] Cannot read metadata for file "/tmp/error.mp3": Unable to probe /tmp/error.mp3 ["path" => "/tmp/error.mp3","exception" => FFMpeg\Exception\RuntimeException^ { …}]
    # 09:33:57 ERROR     [AzuraCast] Symfony\Component\ErrorHandler\Exception\FlattenException: Invalid Podcast Media mime type:  (uncaught exception) at /var/azuracast/www/backend/src/Entity/Repository/PodcastEpisodeRepository.php line 148 while running console command `azuracast:setup:fixtures` ["exception" => Symfony\Component\ErrorHandler\Exception\FlattenException^ {-traceAsString: null …}]
    # 09:33:57 WARNING   [AzuraCast] Console command `azuracast:setup:fixtures` exited with error code 1.

    # In PodcastEpisodeRepository.php line 148:

    # Invalid Podcast Media mime type:
    cp /usr/local/share/icecast/web/error.mp3 /tmp/error.mp3
    until /var/azuracast/www/backend/bin/console azuracast:setup:fixtures; do
        echo "Waiting for database to be ready..."
        sleep 5
    done

    mariadb -u root -p${MARIADB_ROOT_PASSWORD} -e 'DELETE FROM `users` WHERE email = "demo@azuracast.com"' azuracast
    mariadb -u root -p${MARIADB_ROOT_PASSWORD} -e "SET FOREIGN_KEY_CHECKS = 0; TRUNCATE TABLE station; SET FOREIGN_KEY_CHECKS = 1;" azuracast
    mariadb -u root -p${MARIADB_ROOT_PASSWORD} -e "SET FOREIGN_KEY_CHECKS = 0; TRUNCATE TABLE station_mounts; SET FOREIGN_KEY_CHECKS = 1;" azuracast
    mariadb -u root -p${MARIADB_ROOT_PASSWORD} -e "SET FOREIGN_KEY_CHECKS = 0; TRUNCATE TABLE station_hls_streams; SET FOREIGN_KEY_CHECKS = 1;" azuracast
    mariadb -u root -p${MARIADB_ROOT_PASSWORD} -e "SET FOREIGN_KEY_CHECKS = 0; TRUNCATE TABLE station_playlists; SET FOREIGN_KEY_CHECKS = 1;" azuracast

    touch /stationmounts/.installed
fi

if [[ ! -f /tmp/app_configured ]]; then
    touch /tmp/app_configured
    until [[ $(curl -i -H "Accept: application/json" -H "Content-Type:application/json" -X POST "https://api.cylo.io/v1/apps/installed/${INSTANCE_ID}" | grep '200') ]]
        do
        sleep 5
    done
fi
