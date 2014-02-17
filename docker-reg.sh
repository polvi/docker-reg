#!/bin/bash

MACH=$1
PORT=$2
SERV=$3
shift
shift
shift
KV=$@
DOCKER_PORTS=$(/usr/bin/docker port $MACH $PORT)
KV="host=$(echo $DOCKER_PORTS | awk -F':' '{print $1}') $KV"
KV="port=$(echo $DOCKER_PORTS | awk -F':' '{print $2}') $KV"

JSON=
i=0
for kv in $KV; do
  k=$(echo $kv | awk -F'=' '{print $1}')
  v=$(echo $kv | awk -F'=' '{print $2}')
  echo $k $v
  if [ $i -gt 0 ]; then
    JSON="$JSON,"
  fi
  if [[ $v != *[!0-9]* ]]; then
      # $v is an int, treat it as so
      JSON="$JSON \"${k}\": $v"
  else
      JSON="$JSON \"${k}\": \"$v\""
  fi
  i=$((i+1))
done
JSON="{$JSON }"
echo $JSON

CTL="etcdctl -C http://${ETCD_PORT_10000_TCP_ADDR}:${ETCD_PORT_10000_TCP_PORT}"

KEY="/services/${SERV}/${MACH}"
trap "$CTL rm $KEY; exit" SIGHUP SIGINT SIGTERM

while [ 1 ]; do
  $CTL --debug set "$KEY" "${JSON}" --ttl 5
  sleep 1
done
