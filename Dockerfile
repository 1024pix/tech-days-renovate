FROM sbtscala/scala-sbt:eclipse-temurin-17.0.19_10_1.12.14_2.12.21 AS sbt-dependencies

FROM spark:3.5.6-scala2.12-java17-ubuntu AS spark-final

ENV JMX_EXPORTER_AGENT_VERSION=1.5.0
ADD https://github.com/prometheus/jmx_exporter/releases/download/${JMX_EXPORTER_AGENT_VERSION}/jmx_prometheus_javaagent-${JMX_EXPORTER_AGENT_VERSION}.jar /opt/spark/jars

COPY data-processing/target/scala-2.12/data-processing.jar .
