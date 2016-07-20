#!/bin/bash

function getKey() {
  echo $1 | cut -d "=" -f1
}

function getValue() {
  echo $1 | cut -d "=" -f2
}

function envValue() {
 local entry=`env | grep $1`
 echo `getValue $entry`
}

set -ex

#Find the server id
SERVER_ID=${KAFKA_SERVER_ID:-1}
if [ ! -z "$SERVER_ID" ] ; then
  export ADVERTISED_HOST_NAME=`ip ro get 8.8.8.8 | grep -oP "(?<=src )(\S+)"`
  export ADVERTISED_PORT=${KAFKA_ADVERTISED_PORT:-9092}

  # Find the zookeepers exposed in env.
  ZOOKEEPER_CONNECT=""
  for i in `seq 1 15`; do
    ZK_CLIENT_HOST=`envValue ZK_CLIENT_${i}_SERVICE_HOST`
    ZK_CLIENT_PORT=`envValue ZK_CLIENT_${i}_SERVICE_PORT`
    ZK_CLIENT_HOST=`envValue ZOOKEEPER_${i}_PORT_2181_TCP_ADDR`
    ZK_CLIENT_PORT=`envValue ZOOKEEPER_${i}_PORT_2181_TCP_PORT`

    if [ -z "$ZK_CLIENT_HOST" ] || [ -z "$ZK_CLIENT_PORT" ] ; then 
      break
    else
      if [ ! -z $ZOOKEEPER_CONNECT ] ; then
        ZOOKEEPER_CONNECT="${ZOOKEEPER_CONNECT},"
      fi
      ZOOKEEPER_CONNECT="${ZOOKEEPER_CONNECT}${ZK_CLIENT_HOST}:${ZK_CLIENT_PORT}"
    fi
  done

  if [ ! -z "${NAMESPACE+x}" ]; then
    ZOOKEEPER_CONNECT="${ZOOKEEPER_CONNECT}/${NAMESPACE}"
  fi
fi

NUM_PARTITIONS=${NUM_PARTITIONS:-2}

# Build the server configuration
KAFKA_PROPERTIES=${KAFKA_HOME}/config/server.properties
sed -i "s|{{BROKER_ID}}|${SERVER_ID}|g" $KAFKA_PROPERTIES 
sed -i "s|{{ADVERTISED_HOST_NAME}}|${ADVERTISED_HOST_NAME}|g" $KAFKA_PROPERTIES
sed -i "s|{{ADVERTISED_PORT}}|${ADVERTISED_PORT}|g" $KAFKA_PROPERTIES
sed -i "s|{{ZOOKEEPER_CONNECT}}|${ZOOKEEPER_CONNECT}|g" $KAFKA_PROPERTIES
sed -i "s|{{NUM_PARTITIONS}}|${NUM_PARTITIONS}|g" $KAFKA_PROPERTIES

export CLASSPATH=$CLASSPATH:${KAFKA_HOME}/lib/slf4j-log4j12.jar
export JMX_PORT=7203

cat ${KAFKA_HOME}/config/server.properties

trap "$KAFKA_HOME/bin/kafka-server-stop.sh; echo 'Kafka stopped.'; exit" SIGHUP SIGINT SIGTERM

echo "Starting kafka"
${KAFKA_HOME}/bin/kafka-server-start.sh ${KAFKA_HOME}/config/server.properties
