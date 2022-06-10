FROM debian:11 AS base
ARG DUMMY_USER=dummy
ARG UID_GID=10001
ENV NODE_HOME=/opt/nodejs
ENV PATH=${NODE_HOME}/bin:${PATH}
RUN apt-get update && apt-get -y upgrade && \
apt-get -y install \
sudo git fakeroot python3 \
build-essential g++ libx11-dev libxkbfile-dev libsecret-1-dev && \
apt-get -y autoremove && apt-get -y clean && \
groupadd -g ${UID_GID} ${DUMMY_USER} && useradd -m -u ${UID_GID} -d /${DUMMY_USER}/ -g ${DUMMY_USER} ${DUMMY_USER}

FROM base AS downloader
ARG NODE_JS_VERSION=v16.15.0
ARG NODEJS_ARCHIVE_NAME=node-${NODE_JS_VERSION}-linux-x64.tar.gz
ARG NODEJS_ARCHIVE_IN_TMP=/tmp/${NODEJS_ARCHIVE_NAME}
ADD https://nodejs.org/dist/${NODE_JS_VERSION}/${NODEJS_ARCHIVE_NAME} /tmp/
RUN mkdir -p ${NODE_HOME} && tar -xzf ${NODEJS_ARCHIVE_IN_TMP} -C ${NODE_HOME} --strip-components=1 && npm install --global yarn

FROM base
ARG DUMMY_USER=dummy
COPY --chown=${DUMMY_USER}:${DUMMY_USER} --from=downloader ${NODE_HOME}/ ${NODE_HOME}/
