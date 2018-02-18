#!/bin/bash

START_TIME=$SECONDS

PUSHOVER_USER_KEY=$1
PUSHOVER_APP_TOKEN=$2

LOG=/var/log/upload-recent-event-mp4-to-dropbox.sh.log

if [ -z "$1" ]; then
  echo "Usage: $0 PUSHOVER_USER_KEY PUSHOVER_APP_TOKEN" &>> $LOG
  exit 1
fi

if [ -z "$2" ]; then
  echo "Usage: $0 PUSHOVER_USER_KEY PUSHOVER_APP_TOKEN" &>> $LOG
  exit 1
fi

set -euxo pipefail

EVENT_DIR=`find /usr/local/HomeSeer/html/images/hspi_ultranetcam3/snapshots/NetCam001 -type d -printf '%T@ %p\n' | sort -n | tail -1 | cut -f2- -d" "`
EVENT_NAME="${EVENT_DIR##*/}-NetCam001.mp4"
EVENT_MP4_PATH="${EVENT_DIR}/${EVENT_NAME}"

WAIT_COUNT=0
while [ ! -f "${EVENT_MP4_PATH}" ]
do
  if [ $WAIT_COUNT = "60" ]; then
    echo "Timeout waiting for ${EVENT_MP4_PATH}, giving up" &>> $LOG
    exit 1
  fi

  echo "(`printf %02d $WAIT_COUNT`) Waiting for ${EVENT_MP4_PATH} to appear" &>> $LOG
  WAIT_COUNT=$((WAIT_COUNT + 1))
  sleep 2
done

/home/homeseer/scripts/dropbox_uploader.sh upload "${EVENT_MP4_PATH}" "/last_snapshot.mp4" &>> $LOG
echo "" &>> $LOG
/home/homeseer/scripts/dropbox_uploader.sh upload "${EVENT_MP4_PATH}" "${EVENT_NAME}" &>> $LOG
DROPBOX_SHARE_LINK=`/home/homeseer/scripts/dropbox_uploader.sh share "${EVENT_NAME}"` &>> $LOG
DROPBOX_SHARE_LINK="${DROPBOX_SHARE_LINK/> Share link: /}"

echo $DROPBOX_SHARE_LINK &>> $LOG

ELAPSED_TIME=$(($SECONDS - $START_TIME))

curl -s \
  --form-string "token=${PUSHOVER_APP_TOKEN}" \
  --form-string "user=${PUSHOVER_USER_KEY}" \
  --form-string "html=1" \
  --form-string "title=Video available for ${EVENT_NAME}" \
  --form-string "message=Video was generated in ${ELAPSED_TIME} seconds: <a href='${DROPBOX_SHARE_LINK}'>watch video</a>" \
  --form-string "url=$DROPBOX_SHARE_LINK" \
  --form-string "url_title=View ${EVENT_NAME} on Dropbox" \
  https://api.pushover.net/1/messages.json &>> $LOG

echo "" &>> $LOG
echo "Notification for ${EVENT_NAME} sent" &>> $LOG

