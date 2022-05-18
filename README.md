# Docker Hadoop

Initialize HDFS:
```bash
hdfs dfs -mkdir /user

hdfs dfs -mkdir /tmp
hdfs dfs -chmod 777 /tmp

hdfs dfs -mkdir /data
hdfs dfs -chmod 770 /data
hdfs dfs -setfacl -m user:spark:rwx /data
hdfs dfs -setfacl -m default:user:spark:rwx /data
```