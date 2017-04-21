#!/bin/bash

log() {
  echo $1 | logger
}

# CloudWatchに登録する値
usage=$(curl -s http://127.0.0.1:24220/api/plugins.json | jq . | grep buffer_total_queued_size | cut -d ":" -f 2 | grep -o -E [0-9]+ | awk 'BEGIN {n=0} {n=n+$1} END {print n}')

instanceId=$(cat /opt/cloudwatch/aws-scripts-mon/instanceId)
asGroupName=$(cat /opt/cloudwatch/aws-scripts-mon/asGroupName)
region=$(cat /opt/cloudwatch/aws-scripts-mon/region)

cw_opts="--namespace System/Middleware"
cw_opts=${cw_opts}" --metric-name TDAgentQuesize"
cw_opts=${cw_opts}" --dimensions InstanceId=${instanceId}"
cw_opts=${cw_opts}" --unit Megabytes"
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
