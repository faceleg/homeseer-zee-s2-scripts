#!/bin/bash

set -euxo pipefail

LOG=/var/log/upload-recent-event-mp4-to-dropbox.sh.log

EVENT_DIR=`find /usr/local/HomeSeer/html/images/hspi_ultranetcam3/snapshots/NetCam001 -type d -printf '%T@ %p\n' | sort -n | tail -1 | cut -f2- -d" "`
EVENT_NAME="${EVENT_DIR##*/}.mp4"
EVENT_MP4_PATH="${EVENT_DIR}/${EVENT_NAME}"

while [ ! -f "${EVENT_MP4_PATH}" ]
do
  echo "Waiting for ${EVENT_MP4_PATH} to appear" &>> $LOG
  sleep 2
done

/home/homeseer/scripts/dropbox_uploader.sh upload "${EVENT_MP4_PATH}" "/last_snapshot.mp4" &>> $LOG
/home/homeseer/scripts/dropbox_uploader.sh upload "${EVENT_MP4_PATH}" "${EVENT_NAME}" &>> $LOG
