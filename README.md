# Docker Hadoop

Create kerberos keytabs (must be done on kerberos server and the keys should be copied):
```bash
/usr/sbin/kadmin.local addprinc -randkey gw/gw.example.com
/usr/sbin/kadmin.local ktadd -k /etc/security/keytab/gw.service.keytab gw/gw.example.com

/usr/sbin/kadmin.local addprinc -randkey nn/nn.example.com
/usr/sbin/kadmin.local ktadd -k /etc/security/keytab/nn.service.keytab nn/nn.example.com
/usr/sbin/kadmin.local addprinc -randkey dn/dn01.example.com
/usr/sbin/kadmin.local ktadd -k /etc/security/keytab/dn.service.keytab dn/dn01.example.com
/usr/sbin/kadmin.local addprinc -randkey rm/rm.example.com
/usr/sbin/kadmin.local ktadd -k /etc/security/keytab/rm.service.keytab rm/rm.example.com
/usr/sbin/kadmin.local addprinc -randkey nm/nm01.example.com
/usr/sbin/kadmin.local ktadd -k /etc/security/keytab/nm.service.keytab nm/nm01.example.com
/usr/sbin/kadmin.local addprinc -randkey jhs/jhs.example.com
/usr/sbin/kadmin.local ktadd -k /etc/security/keytab/jhs.service.keytab jhs/jhs.example.com

/usr/sbin/kadmin.local addprinc -randkey HTTP/nn.example.com
/usr/sbin/kadmin.local ktadd -k /etc/security/keytab/HTTP.service.keytab HTTP/nn.example.com
/usr/sbin/kadmin.local addprinc -randkey HTTP/rm.example.com
/usr/sbin/kadmin.local ktadd -k /etc/security/keytab/HTTP.service.keytab HTTP/rm.example.com
/usr/sbin/kadmin.local addprinc -randkey HTTP/nm01.example.com
/usr/sbin/kadmin.local ktadd -k /etc/security/keytab/HTTP.service.keytab HTTP/nm01.example.com
/usr/sbin/kadmin.local addprinc -randkey HTTP/jhs.example.com
/usr/sbin/kadmin.local ktadd -k /etc/security/keytab/HTTP.service.keytab HTTP/jhs.example.com
```

Create keystore for HTTPS:
```bash
keytool -genkey -alias nn.example.com -keyalg rsa -keysize 1024 -dname "CN=nn.example.com" -keypass "${KEYPASS:-changeme}" -keystore keystore/hdfs.jks -storepass "${STOREPASS:-changeme}"
keytool -genkey -alias dn01.example.com -keyalg rsa -keysize 1024 -dname "CN=dn01.example.com" -keypass "${KEYPASS:-changeme}" -keystore keystore/hdfs.jks -storepass "${STOREPASS:-changeme}"
chmod 700 hdfs.jks
```

Initialize HDFS:
```bash
kinit -kt /etc/security/keytab/nn.service.keytab nn/nn.example.com
hdfs dfs -mkdir /user
hdfs dfs -chown hdfs:superuser /user

hdfs dfs -mkdir /tmp
hdfs dfs -chmod 777 /tmp
hdfs dfs -chown hdfs:superuser /tmp

hdfs dfs -mkdir /data
hdfs dfs -chown hdfs:hadoop /data
hdfs dfs -chmod 770 /data
hdfs dfs -setfacl -m user:spark:rwx /data
hdfs dfs -setfacl -m default:user:spark:rwx /data
```
