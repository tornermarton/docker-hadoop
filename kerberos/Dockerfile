FROM debian:stable-slim

MAINTAINER Márton Torner <torner.marton@gmail.com>

SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends procps krb5-admin-server \
    && apt-get clean \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd hadoop \
    && useradd -s /bin/bash -g hadoop hdfs \
    && useradd -s /bin/bash -g hadoop yarn \
    && useradd -s /bin/bash -g hadoop mapred \
    && useradd -s /bin/bash -g hadoop spark

RUN mkdir -p /etc/security/keytab

COPY krb5.conf /etc/krb5.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod a+x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
