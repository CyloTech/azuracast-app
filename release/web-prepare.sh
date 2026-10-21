#!/bin/sh
# Run by release/in-image-report.sh before nginx -t (gate_web_prepare): render
# the nginx configuration the way the container does at start, so the gate
# tests the real vhost. 01_self_signed_ssl.sh creates the self-signed
# certificate the vhost loads; 05_nginx_conf.sh renders nginx.conf and the
# AzuraCast vhost from their templates.
set -e
/etc/my_init.d/01_self_signed_ssl.sh
/etc/my_init.d/05_nginx_conf.sh
