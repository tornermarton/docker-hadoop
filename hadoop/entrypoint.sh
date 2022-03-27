#!/bin/bash

# Set some sensible defaults
export CORE_CONF_fs_defaultFS=${CORE_CONF_fs_defaultFS:-hdfs://`hostname -f`:8020}

export HDFS_CONF_dfs_namenode_name_dir=${HDFS_CONF_dfs_namenode_data_dir:-/data/0/nn}
export HDFS_CONF_dfs_datanode_data_dir=${HDFS_CONF_dfs_datanode_data_dir:-/data/0/dn}
export HDFS_CONF_dfs_journalnode_edits_dir=${HDFS_CONF_dfs_journalnode_edits_dir:-/data/0/jn}

export SPARK_CONF_spark_master=${SPARK_CONF_spark_master:-yarn}

function addProperty() {
  local path=$1
  local name=$2
  local value=$3

  local entry="<property><name>$name</name><value>${value}</value></property>"
  local escapedEntry=$(echo "$entry" | sed 's/\//\\\//g')
  sed -i "/<\/configuration>/ s/.*/${escapedEntry}\n&/" "$path"
}

function addPropertySpark() {
  local path=$1
  local name=$2
  local value=$3

  printf "%s %s\n" "${name}" "${value}" >> "${path}"
}

function configure() {
    local path=$1
    local module=$2
    local envPrefix=$3

    if [ ! -f "$path" ]; then
      printf "<configuration>\n</configuration>" > "$path"
    fi

    local var
    local value

    echo "Configuring $module"
    for c in $(printenv | perl -sne 'print "$1 " if m/^${envPrefix}_(.+?)=.*/' -- -envPrefix="$envPrefix"); do
        name=$(echo "${c}" | perl -pe 's/___/-/g; s/__/@/g; s/_/./g; s/@/_/g;')
        var="${envPrefix}_${c}"
        value=${!var}
        echo " - Setting $name=$value"
        addProperty "$path" "$name" "$value"
    done
}

function configureSpark() {
    local path=$1
    local module=$2
    local envPrefix=$3

    local var
    local value

    echo "Configuring $module"
    for c in $(printenv | perl -sne 'print "$1 " if m/^${envPrefix}_(.+?)=.*/' -- -envPrefix="$envPrefix"); do
        name=$(echo "${c}" | perl -pe 's/___/-/g; s/__/@/g; s/_/./g; s/@/_/g;')
        var="${envPrefix}_${c}"
        value=${!var}
        echo " - Setting $name=$value"
        addPropertySpark "$path" "$name" "$value"
    done
}

configure "$HADOOP_CONF_DIR/core-site.xml" core CORE_CONF
configure "$HADOOP_CONF_DIR/hdfs-site.xml" hdfs HDFS_CONF
configure "$HADOOP_CONF_DIR/yarn-site.xml" yarn YARN_CONF
configure "$HADOOP_CONF_DIR/httpfs-site.xml" httpfs HTTPFS_CONF
configure "$HADOOP_CONF_DIR/kms-site.xml" kms KMS_CONF
configure "$HADOOP_CONF_DIR/mapred-site.xml" mapred MAPRED_CONF
configure "$HADOOP_CONF_DIR/ssl-server.xml" ssl SSL_CONF

configureSpark "$SPARK_CONF_DIR/spark-defaults.conf" spark SPARK_CONF

if [ "$MULTIHOMED_NETWORK" = "1" ]; then
    echo "Configuring for multihomed network"

    # HDFS
    addProperty "$HADOOP_CONF_DIR/hdfs-site.xml" dfs.namenode.rpc-bind-host 0.0.0.0
    addProperty "$HADOOP_CONF_DIR/hdfs-site.xml" dfs.namenode.servicerpc-bind-host 0.0.0.0
    addProperty "$HADOOP_CONF_DIR/hdfs-site.xml" dfs.namenode.http-bind-host 0.0.0.0
    addProperty "$HADOOP_CONF_DIR/hdfs-site.xml" dfs.namenode.https-bind-host 0.0.0.0
    addProperty "$HADOOP_CONF_DIR/hdfs-site.xml" dfs.client.use.datanode.hostname true
    addProperty "$HADOOP_CONF_DIR/hdfs-site.xml" dfs.datanode.use.datanode.hostname true

    # YARN
    addProperty "$HADOOP_CONF_DIR/yarn-site.xml" yarn.resourcemanager.bind-host 0.0.0.0
    addProperty "$HADOOP_CONF_DIR/yarn-site.xml" yarn.nodemanager.bind-host 0.0.0.0
    addProperty "$HADOOP_CONF_DIR/yarn-site.xml" yarn.timeline-service.bind-host 0.0.0.0

    # MAPRED
    addProperty "$HADOOP_CONF_DIR/mapred-site.xml" yarn.nodemanager.bind-host 0.0.0.0
fi

function wait_for_it()
{
    local serviceport=$1
    local service=${serviceport%%:*}
    local port=${serviceport#*:}
    local retry_seconds=5
    local max_try=100
    let i=1

    nc -z $service $port
    result=$?

    until [ $result -eq 0 ]; do
      echo "[$i/$max_try] check for ${service}:${port}..."
      echo "[$i/$max_try] ${service}:${port} is not available yet"
      if (( $i == $max_try )); then
        echo "[$i/$max_try] ${service}:${port} is still not available; giving up after ${max_try} tries. :/"
        exit 1
      fi

      echo "[$i/$max_try] try in ${retry_seconds}s once again ..."
      let "i++"
      sleep $retry_seconds

      nc -z "$service" "$port"
      result=$?
    done
    echo "[$i/$max_try] $service:${port} is available."
}

for i in "${SERVICE_PRECONDITION[@]}"
do
    wait_for_it "${i}"
done

for i in "$@" ; do
    if [[ $i == "namenode" ]] ; then
        if [ "$(ls -A "$HDFS_CONF_dfs_namenode_name_dir")" == "" ]; then
          hdfs namenode -format
        fi

        break
    fi
done

exec "$@"
