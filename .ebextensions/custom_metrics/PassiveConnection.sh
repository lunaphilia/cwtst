#!/bin/bash

log() {
  echo $1 | logger
}

# CloudWatchに登録する値
usage=$(netstat -s | awk ' /passive connection ope/ { print $1 }')

instanceId=$(cat /opt/cloudwatch/aws-scripts-mon/instanceId)
asGroupName=$(cat /opt/cloudwatch/aws-scripts-mon/asGroupName)
region=$(cat /opt/cloudwatch/aws-scripts-mon/region)

cw_opts="--namespace System/Network"
cw_opts=${cw_opts}" --metric-name PassiveConnection"
cw_opts=${cw_opts}" --dimensions InstanceId=${instanceId}"
cw_opts=${cw_opts}" --unit Count"
cw_opts=${cw_opts}" --region ${region}"
cw_opts=${cw_opts}" --value ${usage}"

# cron等でAPIリクエストが集中するのを防ぐためある程度wait
sleep $(($RANDOM % 15))

counter=0
MAX_RETRY=3

while :; do
  aws cloudwatch put-metric-data ${cw_opts}
  if [ $? -ne 0 ]; then
    if [ "${counter}" -ge "${MAX_RETRY}" ]; then
      log "failed to put metrics."
      exit 1
    fi
  else
    break
  fi

  counter=$((counter + 1))
  sleep 10
done

exit 0
