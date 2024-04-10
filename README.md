# ace-tls-broker-file
TLS connectivity using a .broker file

Change the port number in the broker files to the correct port

Run the `create-key-and-trust-stores.sh` script, which should create the
key and truststores, create a broker, and configure it before starting it.
The overrides node.conf.yaml will be updated by the script:
```
# This will add the TLS configuration to the existing
# overrides node.conf.yaml, which ends with
#
# RestAdminListener:
#   port: 4419
echo "  sslCertificate: '$PWD/acekeystore.p12'" >> /var/mqsi/components/TLSBroker/overrides/node.conf.yaml
echo "  sslPassword: 'changeit'" >> /var/mqsi/components/TLSBroker/overrides/node.conf.yaml
```

After this, running
```
mqsilist -n ./tls-connect-jks.broker
```
should connect successfully.
