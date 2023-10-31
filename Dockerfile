FROM openjdk:17-slim-buster as builder

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates binutils wget \
    && rm -rf /var/lib/apt/lists/*

RUN jlink \
         --add-modules ALL-MODULE-PATH \
         --strip-debug \
         --no-man-pages \
         --no-header-files \
         --compress=2 \
         --output /javaruntime

ARG VERSION
WORKDIR application

RUN set -ex \
    && wget https://github.com/wojiushixiaobai/halo/releases/download/${VERSION}/halo-${VERSION}.tar.gz \
    && tar -xvf halo-${VERSION}.tar.gz --strip-components=1 \
    && rm -rf halo-${VERSION}.tar.gz \
    && java -Djarmode=layertools -jar application.jar extract

FROM debian:buster-slim

LABEL org.opencontainers.image.source https://github.com/wojiushixiaobai/halo

ENV JAVA_HOME=/opt/java/openjdk
ENV PATH "${JAVA_HOME}/bin:${PATH}"
COPY --from=builder /javaruntime $JAVA_HOME

WORKDIR application

COPY --from=builder application/dependencies/ ./
COPY --from=builder application/spring-boot-loader/ ./
COPY --from=builder application/snapshot-dependencies/ ./
COPY --from=builder application/application/ ./

ENV JVM_OPTS="-Xmx256m -Xms256m" \
    HALO_WORK_DIR="/root/.halo2" \
    SPRING_CONFIG_LOCATION="optional:classpath:/;optional:file:/root/.halo2/" \
    TZ=Asia/Shanghai

RUN ln -sf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone

ENTRYPOINT ["sh", "-c", "java ${JVM_OPTS} org.springframework.boot.loader.JarLauncher ${0} ${@}"]