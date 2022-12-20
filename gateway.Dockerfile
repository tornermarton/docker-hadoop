FROM python:3.10-slim

MAINTAINER Márton Torner <torner.marton@gmail.com>

SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update \
    && apt install -y --no-install-recommends apt-transport-https ca-certificates wget dirmngr gnupg software-properties-common \
    && wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | apt-key add - \
    && add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/ \
    && apt update \
    && apt install -y --no-install-recommends adoptopenjdk-8-hotspot wget curl procps krb5-user openssh-server
ENV JAVA_HOME=/usr/lib/jvm/adoptopenjdk-8-hotspot-amd64/

# Configure ssh server
RUN mkdir /var/run/sshd;                                                                                 \
    sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config;               \
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd;  \
    echo "export VISIBLE=now" >> /etc/profile
ENV NOTVISIBLE "in users profile"

ENV HADOOP_VERSION 3.3.2
ENV HADOOP_HOME /opt/hadoop
ENV HADOOP_CONF_DIR ${HADOOP_HOME}/etc/hadoop
ENV LD_LIBRARY_PATH ${HADOOP_HOME}/lib/native:${LD_LIBRARY_PATH}

RUN wget https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz \
    && tar -xzf hadoop-${HADOOP_VERSION}.tar.gz --exclude=hadoop-${HADOOP_VERSION}/share/doc \
    && mv hadoop-${HADOOP_VERSION} /opt/hadoop-${HADOOP_VERSION} \
    && ln -s /opt/hadoop-${HADOOP_VERSION} ${HADOOP_HOME} \
    && rm hadoop-${HADOOP_VERSION}.tar.gz
ENV PATH ${PATH}:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin

ENV SPARK_VERSION 3.2.3
ENV SPARK_HADOOP_VERSION 3.2
ENV SPARK_HOME /opt/spark
ENV SPARK_CONF_DIR ${SPARK_HOME}/conf

RUN wget https://dlcdn.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${SPARK_HADOOP_VERSION}.tgz \
    && tar -xzf spark-${SPARK_VERSION}-bin-hadoop${SPARK_HADOOP_VERSION}.tgz \
    && mv spark-${SPARK_VERSION}-bin-hadoop${SPARK_HADOOP_VERSION} /opt/spark-${SPARK_VERSION}-bin-hadoop${SPARK_HADOOP_VERSION} \
    && ln -s /opt/spark-${SPARK_VERSION}-bin-hadoop${SPARK_HADOOP_VERSION} ${SPARK_HOME} \
    && rm spark-${SPARK_VERSION}-bin-hadoop${SPARK_HADOOP_VERSION}.tgz
ENV PATH ${PATH}:${SPARK_HOME}/bin:${SPARK_HOME}/sbin

RUN groupadd hadoop \
    && useradd -s /bin/bash -g hadoop hdfs \
    && useradd -s /bin/bash -g hadoop yarn \
    && useradd -s /bin/bash -g hadoop mapred \
    && useradd -s /bin/bash -g hadoop spark
RUN chown -R -L hdfs:hadoop ${HADOOP_HOME} && chmod -R 770 ${HADOOP_HOME}
RUN chown -R -L spark:hadoop ${SPARK_HOME} && chmod -R 770 ${SPARK_HOME}

# Create user to use at SSH connection
# !!!IMPORTANT: PASSWORD MUST BE CHANGED IMMIDIATELY AFTER FIRST LOGIN!!!
RUN useradd -s /bin/bash -g hadoop -m gw;                        \
    echo 'gw:nehezjelszo' | chpasswd;                      \
    mkdir /home/gw/code;                                   \
    mkdir /home/gw/.ssh
RUN chown -R gw:hadoop /home/gw/

RUN mkdir -p /data/0/nn /data/0/dn /data/0/jn && chown -R hdfs:hadoop /data

COPY krb5.conf /etc/krb5.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod a+x /entrypoint.sh

EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D"]
