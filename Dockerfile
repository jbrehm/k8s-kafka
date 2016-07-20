# Dockerfile for running a Kafka ensemble (primarily in Kubernetes)
# - Mashup of wurstmeister and graeme johnson's k8s-kafka
# - Apache Kafka 0.8.2.1 from binary distribution.
# - Base of Alpine Linux (small) 
FROM anapsix/alpine-java 

MAINTAINER Justin Brehm <jbrehm@reverbnation.com>

RUN mkdir -p /opt/kafka /data /logs \
    && apk add --update unzip wget curl docker jq coreutils gnupg

ENV KAFKA_VERSION="0.8.2.1" SCALA_VERSION="2.11"

# Download Kafka binary distribution
ADD http://www.us.apache.org/dist/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz /tmp/
ADD https://dist.apache.org/repos/dist/release/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz.asc /tmp/
RUN echo VERIFY DOWNLOAD: && \
  gpg --recv-keys E0A61EEA && \
  gpg --verify /tmp/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz.asc /tmp/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz 2>/dev/null && \
  tar -zx -C /opt -f /tmp/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz && rm -rf /tmp/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz.*

ENV KAFKA_HOME /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}
WORKDIR $KAFKA_HOME

ADD http://repo1.maven.org/maven2/org/slf4j/slf4j-log4j12/1.7.6/slf4j-log4j12-1.7.6.jar ${KAFKA_HOME}/libs/
ADD config ${KAFKA_HOME}/config
ADD config-and-run.sh ${KAFKA_HOME}

ENV PATH ${KAFKA_HOME}/bin:$PATH

# primary, jmx
EXPOSE 9092 7203

VOLUME [ "/data", "/logs" ]

ENTRYPOINT ["./config-and-run.sh"]
