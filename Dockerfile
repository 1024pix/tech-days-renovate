# The sbtscala/scala-sbt tag encodes three versions that also live elsewhere in
# the repo, in a shape the dockerfile manager cannot parse. Splitting it into ARGs
# lets customManagers:dockerfileVersions track each one separately.
# renovate: datasource=docker depName=eclipse-temurin extractVersion=^(?<version>\d+\.\d+\.\d+_\d+)-jdk$
ARG JAVA_VERSION=17.0.19_10
# renovate: datasource=github-releases depName=sbt/sbt extractVersion=^v(?<version>\S+)$
ARG SBT_VERSION=1.12.14
# renovate: datasource=maven depName=org.scala-lang:scala-library
ARG SCALA_VERSION=2.12.21

FROM sbtscala/scala-sbt:eclipse-temurin-${JAVA_VERSION}_${SBT_VERSION}_${SCALA_VERSION} AS sbt-dependencies

FROM spark:3.5.6-scala2.12-java17-ubuntu AS spark-final

# renovate: datasource=github-releases depName=prometheus/jmx_exporter
ENV JMX_EXPORTER_AGENT_VERSION=1.6.0
ADD https://github.com/prometheus/jmx_exporter/releases/download/${JMX_EXPORTER_AGENT_VERSION}/jmx_prometheus_javaagent-${JMX_EXPORTER_AGENT_VERSION}.jar /opt/spark/jars

COPY data-processing/target/scala-2.12/data-processing.jar .
