#!/bin/sh
 
# switch to this script's directory
cd "$(dirname "$0")"

rm *.crt
rm *.key
rm *.p12
rm *.srl
rm *.pem
rm *.ks
rm *.ts
rm *.csr
rm *.cer

SERVER_NAME=localhost
CLIENT_NAME=127.0.0.1
PFX_PASSWORD=password
JAVA_HOME=/home/anarvaez/files/dev/jdk1.8.0_221
PATH=$JAVA_HOME/bin:$PATH
PATH_TO_SB2_PROJECT=../sb2-soap-proxy-with-ssl-example

printf "\n\n%s\n" "STEP 1: creating CA..."
openssl req -nodes -x509 -newkey rsa:2048 -keyout ca.key -out ca.crt -subj "/C=US/ST=NC/L=Raleigh/O=Red Hat/OU=Support/CN=TEST CA"
 
printf "\n\n%s\n" "STEP 2: creating Server cert..."

#to create alternate names, recommended way is to follow suggestions from here: 
#https://access.redhat.com/documentation/en-us/red_hat_fuse/7.5/html/apache_cxf_security_guide/ManageCertsCxf#i382787

#openssl req -nodes -newkey rsa:2048 -keyout server.key -out server.csr -subj "/C=US/ST=NC/L=Raleigh/O=Red Hat/OU=Support/CN=$SERVER_NAME" -addext "subjectAltName = DNS:$SERVER_NAME" 
openssl req -nodes -newkey rsa:2048 -keyout server.key -out server.csr -subj "/C=US/ST=NC/L=Raleigh/O=Red Hat/OU=Support/CN=$SERVER_NAME" 
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt
cat server.key server.crt > server.pem

 
printf "\n\b%s\n" "STEP 3: creating Client cert..."

#to create alternate names, recommended way is to follow suggestions from here: 
#https://access.redhat.com/documentation/en-us/red_hat_fuse/7.5/html/apache_cxf_security_guide/ManageCertsCxf#i382787

#openssl req -nodes -newkey rsa:2048 -keyout client.key -out client.csr -subj "/C=US/ST=NC/L=Raleigh/O=Red Hat/OU=Support/CN=$CLIENT_NAME" -addext "subjectAltName = DNS:$CLIENT_NAME"
openssl req -nodes -newkey rsa:2048 -keyout client.key -out client.csr -subj "/C=US/ST=NC/L=Raleigh/O=Red Hat/OU=Support/CN=$CLIENT_NAME" 
openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAserial ca.srl -out client.crt
cat client.key client.crt > client.pem
 
printf "\n\b%s\n" "STEP 4: creating pfx files..."
openssl pkcs12 -inkey client.key -in client.crt -export -out client.p12 -password pass:$PFX_PASSWORD
openssl pkcs12 -inkey server.key -in server.crt -export -out server.p12 -password pass:$PFX_PASSWORD
 
printf "\n\b%s\n" "STEP 4: creating keystore/truststore files..."
keytool -importkeystore -srckeystore server.p12 -destkeystore server.ks -srcstoretype PKCS12 -deststoretype jks -deststorepass $PFX_PASSWORD -srcstorepass $PFX_PASSWORD
keytool -importkeystore -srckeystore client.p12 -destkeystore client.ks -srcstoretype PKCS12 -deststoretype jks -deststorepass $PFX_PASSWORD -srcstorepass $PFX_PASSWORD
keytool -export -keystore server.ks -file server.cer -storepass $PFX_PASSWORD -alias 1
keytool -export -keystore client.ks -file client.cer -storepass $PFX_PASSWORD -alias 1

keytool -import -alias ca -keystore client.ts -file ca.crt -storepass $PFX_PASSWORD -noprompt 
keytool -import -alias ca -keystore server.ts -file ca.crt -storepass $PFX_PASSWORD -noprompt   
keytool -import -alias server -keystore server.ts -file server.cer -storepass $PFX_PASSWORD -keypass $PFX_PASSWORD -noprompt 
keytool -import -alias server -keystore client.ts -file server.cer -storepass $PFX_PASSWORD -keypass $PFX_PASSWORD -noprompt 
keytool -import -alias client -keystore server.ts -file client.cer -storepass $PFX_PASSWORD -keypass $PFX_PASSWORD -noprompt 
keytool -import -alias client -keystore client.ts -file client.cer -storepass $PFX_PASSWORD -keypass $PFX_PASSWORD -noprompt 

printf "\n\n%s\n" "STEP 5: Copying keystore and truststore to SB2 project"
cp server.ks $PATH_TO_SB2_PROJECT/src/main/resources/keystore.jks
cp server.ts $PATH_TO_SB2_PROJECT/src/main/resources/truststore.jks

