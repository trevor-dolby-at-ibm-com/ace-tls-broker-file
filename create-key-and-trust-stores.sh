#!/bin/bash

set -x

keytool -genkey -alias acecert -keyalg RSA -keystore acekeystore.p12 -storepass changeit -storetype pkcs12 -dname "CN=aceuser, OU=ExpertLabs, O=IBM, L=Minneapolis, ST=MN, C=US"  -keypass changeit

# This one can be a ".p12" file
keytool -export -alias acecert -keystore acekeystore.p12 -storepass changeit -storetype pkcs12 -file acepublickey.cer

# Note that the truststore has to be named ".pkcs12" and not ".p12" in order to work with ACE commands using a .broker file
keytool -import -noprompt -v -trustcacerts -alias acecert -keystore acetruststore.pkcs12 -storepass changeit -storetype pkcs12 -file acepublickey.cer 
keytool -import -noprompt -v -trustcacerts -alias acecert -keystore acetruststore.jks -storepass changeit -storetype jks -file acepublickey.cer 

mqsicreatebroker TLSBroker
# This will add the TLS configuration to the existing
# overrides node.conf.yaml, which ends with
#
# RestAdminListener:
#   port: 4419
echo "  sslCertificate: '$PWD/acekeystore.p12'" >> /var/mqsi/components/TLSBroker/overrides/node.conf.yaml
echo "  sslPassword: 'changeit'" >> /var/mqsi/components/TLSBroker/overrides/node.conf.yaml

mqsistart TLSBroker
