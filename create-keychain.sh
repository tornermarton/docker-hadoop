keytool -genkey -alias nn.example.com -keyalg rsa -keysize 1024 -dname "CN=nn.example.com" -keypass "${KEYPASS:-changeme}" -keystore hdfs.jks -storepass "${STOREPASS:-changeme}"
keytool -genkey -alias dn01.example.com -keyalg rsa -keysize 1024 -dname "CN=dn01.example.com" -keypass "${KEYPASS:-changeme}" -keystore hdfs.jks -storepass "${STOREPASS:-changeme}"
chmod 700 hdfs.jks