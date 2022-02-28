FROM lisacumt/hadoop-hive-hbase-spark-docker:1.0.1

# https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV USR_BIN_DIR=/usr/source_dir
RUN mkdir -p "${USR_BIN_DIR}"
# 使用本地的源文件，加快rebuild速度，方便调试
COPY tar-source-files/* "${USR_BIN_DIR}/"
WORKDIR "${USR_BIN_DIR}"


ARG ZEPPELIN_VERSION=0.9.0
ENV ZEPPELIN_HOME=/usr/zeppelin
ENV ZEPPELIN_PACKAGE="zeppelin-${ZEPPELIN_VERSION}-bin-all.tgz"
# 国内加速地址，注意版本不全
# https://mirrors.aliyun.com/apache/zeppelin/zeppelin-${ZEPPELIN_VERSION}/zeppelin-${ZEPPELIN_VERSION}-bin-all.tgz
# 如果${USR_BIN_DIR}不存在，则下载
RUN if [ ! -f "${ZEPPELIN_PACKAGE}" ]; then curl --progress-bar -L --retry 3 \
    "https://archive.apache.org/dist/zeppelin/zeppelin-${ZEPPELIN_VERSION}/${ZEPPELIN_PACKAGE}" \
	-o "${USR_BIN_DIR}/${ZEPPELIN_PACKAGE}" ; fi \
	&& tar -xf "${ZEPPELIN_PACKAGE}" -C /usr/ \
    && mv "/usr/zeppelin-${ZEPPELIN_VERSION}-bin-all" "${ZEPPELIN_HOME}" \
    && chown -R root:root "${ZEPPELIN_HOME}" \
    && cp "${HIVE_HOME}/jdbc/hive-jdbc-${HIVE_VERSION}-standalone.jar" "${ZEPPELIN_HOME}/interpreter/jdbc" \
    && rm -rf "${USR_BIN_DIR}/*"

ENV MASTER=yarn-client
ENV PATH="${PATH}:${ZEPPELIN_HOME}/bin"
ENV ZEPPELIN_CONF_DIR "${ZEPPELIN_HOME}/conf"
COPY conf/interpreter.json "${ZEPPELIN_CONF_DIR}"
ENV ZEPPELIN_ADDR=0.0.0.0
ENV ZEPPELIN_PORT=8890
ENV ZEPPELIN_NOTEBOOK_DIR="/zeppelin_notebooks"

# Clean up
RUN rm -rf "${ZEPPELIN_HOME}/interpreter/alluxio" \
    && rm -rf "${ZEPPELIN_HOME}/interpreter/angular" \
    && rm -rf "${ZEPPELIN_HOME}/interpreter/bigquery" \
    && rm -rf "${ZEPPELIN_HOME}/interpreter/cassandra" \
    && rm -rf "${ZEPPELIN_HOME}/interpreter/elasticsearch" \
    && rm -rf "${ZEPPELIN_HOME}/interpreter/flink" \
    && rm -rf "${ZEPPELIN_HOME}/interpreter/groovy" \
#    && rm -rf "${ZEPPELIN_HOME}/interpreter/hbase" \
    && rm -rf "${ZEPPELIN_HOME}/interpreter/ignite" \
    && rm -rf "${ZEPPELIN_HOME}/interpreter/kylin" \
    && rm -rf "${ZEPPELIN_HOME}/interpreter/lens" \
    && rm -rf "${ZEPPELIN_HOME}/interpreter/neo4j" \
    && rm -rf "${ZEPPELIN_HOME}/interpreter/pig" \
    && rm -rf "${ZEPPELIN_HOME}/interpreter/sap" \
    && rm -rf "${ZEPPELIN_HOME}/interpreter/scio"

HEALTHCHECK CMD curl -f "http://host.docker.internal:${ZEPPELIN_PORT}/" || exit 1

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]