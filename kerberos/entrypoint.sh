#! /bin/bash

if [ -n "${KERBEROS_PASSWORD_FILE}" ]; then
  KERBEROS_PASSWORD=$(cat "${KERBEROS_PASSWORD_FILE}")
fi

if [ -n "${KEYPASS_FILE}" ]; then
  KEYPASS=$(cat "${KEYPASS_FILE}")
fi

if [ -n "${STOREPASS_FILE}" ]; then
  STOREPASS=$(cat "${STOREPASS_FILE}")
fi

/usr/sbin/kdb5_util -P "${KERBEROS_PASSWORD:-changeme}" create -s

/usr/sbin/kadmin.local -q "addprinc -randkey nn/nn.example.com"
/usr/sbin/kadmin.local -q "ktadd -k /etc/security/keytab/nn.service.keytab nn/nn.example.com"
chown hdfs:hadoop /etc/security/keytab/nn.service.keytab

/usr/sbin/kadmin.local -q "addprinc -randkey dn/dn01.example.com"
/usr/sbin/kadmin.local -q "ktadd -k /etc/security/keytab/dn.service.keytab dn/dn01.example.com"
chown hdfs:hadoop /etc/security/keytab/dn.service.keytab

/usr/sbin/kadmin.local -q "addprinc -randkey rm/rm.example.com"
/usr/sbin/kadmin.local -q "ktadd -k /etc/security/keytab/rm.service.keytab rm/rm.example.com"
chown yarn:hadoop /etc/security/keytab/rm.service.keytab

/usr/sbin/kadmin.local -q "addprinc -randkey nm/nm01.example.com"
/usr/sbin/kadmin.local -q "ktadd -k /etc/security/keytab/nm.service.keytab nm/nm01.example.com"
chown yarn:hadoop /etc/security/keytab/nm.service.keytab

/usr/sbin/kadmin.local -q "addprinc -randkey jhs/jhs.example.com"
/usr/sbin/kadmin.local -q "ktadd -k /etc/security/keytab/jhs.service.keytab jhs/jhs.example.com"
chown mapred:hadoop /etc/security/keytab/jhs.service.keytab

/usr/sbin/kadmin.local -q "addprinc -randkey gw/gw.example.com"
/usr/sbin/kadmin.local -q "ktadd -k /etc/security/keytab/gw.service.keytab gw/gw.example.com"
chown mapred:hadoop /etc/security/keytab/gw.service.keytab

/usr/sbin/kadmin.local -q "addprinc -randkey HTTP/nn.example.com"
/usr/sbin/kadmin.local -q "ktadd -k /etc/security/keytab/spnego.service.keytab HTTP/nn.example.com"
chown hdfs:hadoop /etc/security/keytab/spnego.service.keytab

keytool -genkey -alias nn.example.com -keyalg rsa -keysize 1024 -dname "CN=nn.example.com" -keypass "${KEYPASS:-changeme}" -keystore /etc/security/keytab/hdfs.jks -storepass "${STOREPASS:-changeme}"
keytool -genkey -alias dn01.example.com -keyalg rsa -keysize 1024 -dname "CN=dn01.example.com" -keypass "${KEYPASS:-changeme}" -keystore /etc/security/keytab/hdfs.jks -storepass "${STOREPASS:-changeme}"
chmod 700 /etc/security/keytab/hdfs.jks
chown hdfs:hadoop /etc/security/keytab/hdfs.jks

krb5kdc -n
