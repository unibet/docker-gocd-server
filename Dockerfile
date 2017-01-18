# We need edge for the xmlstarlet package right now.
FROM alpine:3.5
MAINTAINER karel.bemelmans@unibet.com

# Install more apk packages we might need
RUN apk --no-cache --update add \
  apache2-utils \
  bash \
  ca-certificates \
  curl \
  git \
  openjdk8-jre \
  rpm \
  subversion \
  xmlstarlet \
  && rm -rf /var/cache/apk/*

# Add go user and group
RUN addgroup -g 500 go && adduser -u 500 -h /var/lib/go-server -H -S -G go go

# Install GoCD Server from zip file
ARG GO_MAJOR_VERSION=17.1.0
ARG GO_BUILD_VERSION=4511
ARG GO_VERSION="${GO_MAJOR_VERSION}-${GO_BUILD_VERSION}"
ARG GOCD_SHA256=caa68da42f5ad54c52331ff1f7ecbbe8ab48fab66600c23638f17e4ab5d77d24

RUN curl -L --silent https://download.gocd.io/binaries/${GO_VERSION}/generic/go-server-${GO_VERSION}.zip \
       -o /tmp/go-server.zip \
  && echo "${GOCD_SHA256}  /tmp/go-server.zip" | sha256sum -c - \
  && unzip /tmp/go-server.zip -d /usr/local \
  && ln -s /usr/local/go-server-${GO_MAJOR_VERSION} /usr/local/go-server \
  && chown -R go:go /usr/local/go-server-${GO_MAJOR_VERSION} \
  && rm /tmp/go-server.zip

RUN mkdir -p /etc/default \
  && cp /usr/local/go-server-${GO_MAJOR_VERSION}/go-server.default /etc/default/go-server \
  && sed -i -e "s/DAEMON=Y/DAEMON=N/" /etc/default/go-server

RUN mkdir /etc/go && chown go:go /etc/go \
  && mkdir /var/lib/go-server && chown go:go /var/lib/go-server \
  && mkdir /var/log/go-server && chown go:go /var/log/go-server

# Expose ports needed
EXPOSE 8153 8154

VOLUME /etc/go
VOLUME /var/lib/go-server
VOLUME /var/log/go-server

# add the entrypoint config and run it when we start the container
COPY ./docker-entrypoint.sh /
RUN chown go:go /docker-entrypoint.sh && chmod 500 /docker-entrypoint.sh

USER go
ENTRYPOINT ["/docker-entrypoint.sh"]
