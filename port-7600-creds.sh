#!/bin/bash

# Based on instructions at https://www.ibm.com/support/pages/collecting-service-level-trace-ace-integration-server?view=full

# Exit on error
set -e
# Log everything
#set -x

IR_NAME=$1
LOCAL_PORT_NUMBER=$2

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <IR name> <local forwarding port>"
    exit 1
fi

echo "Checking for IR ${IR_NAME}"
oc get IntegrationRuntime ${IR_NAME}


echo "========================================================================"
echo "Pulling TLS keys"
echo $(oc get secrets ${IR_NAME}-ir-adminssl -o template --template '{{index .data "configuration"}}') | base64 -d > ${IR_NAME}-adminssl.zip
unzip ${IR_NAME}-adminssl.zip
mv tls.key.pem ${IR_NAME}-tls.key.pem
mv tls.crt.pem ${IR_NAME}-tls.crt.pem
mv ca.crt.pem ${IR_NAME}-ca.crt.pem
echo "========================================================================"
echo "Pulling admin auth creds"
oc get secrets ${IR_NAME}-ir --template '{{.data.adminusers}}' | base64 -d | tr ' ' ':' > ${IR_NAME}-admin-user-pw.txt

# Optional - curl will work with the above data but these help with other tools
echo "========================================================================"
echo "Creating PKCS12 keystore"
openssl pkcs12 -chain -CAfile ${IR_NAME}-ca.crt.pem -inkey ${IR_NAME}-tls.key.pem -in ${IR_NAME}-tls.crt.pem -export -out ${IR_NAME}-port-7600.pkcs12 -passin pass:changeit -passout pass:changeit  -legacy
keytool -import -noprompt -v -trustcacerts -alias acecert -keystore ${IR_NAME}-port-7600.pkcs12 -storepass changeit -storetype pkcs12 -file ${IR_NAME}-ca.crt.pem
echo "========================================================================"

USERPW=$(cat ${IR_NAME}-admin-user-pw.txt)
USER=${USERPW%:*}
PW=${USERPW#*:}

echo "Creating ${IR_NAME}-port-7600.broker for mqsi* commands"
cat <<EOF > ${IR_NAME}-port-7600.broker
<?xml version="1.0" encoding="UTF-8"?>
<IntegrationServerConnectionParameters Version="11.0.0"
host="localhost" listenerPort="${LOCAL_PORT_NUMBER}"
userName="${USER}" password="${PW}"
sslTrustStorePath="${IR_NAME}-port-7600.pkcs12" sslTrustStorePassword="changeit"
sslKeyStorePath="${IR_NAME}-port-7600.pkcs12" sslKeyStorePassword="changeit"
useSsl="true" xmlns="http://www.ibm.com/xmlns/prod/ace/11"/>
EOF

export POD_NAME=$(oc get pods | grep ${IR_NAME}-ir | tr ' ' '\n' | grep ${IR_NAME}-ir)

echo "========================================================================"
echo "Files created successfully"
echo "========================================================================"
echo ""
echo "To access the server, please run the following port forwarding command in a separate terminal:"
echo ""
echo "    " "oc port-forward ${POD_NAME} ${LOCAL_PORT_NUMBER}:7600"
echo ""

echo "To use curl:"
echo ""
echo "    " curl -u '`'cat ${IR_NAME}-admin-user-pw.txt'`' --cert ${IR_NAME}-tls.crt.pem --key ${IR_NAME}-tls.key.pem -k https://localhost:${LOCAL_PORT_NUMBER}/apiv2
echo ""

echo "To use mqsilist:"
echo ""
echo "    " mqsilist --integration-node-file ${IR_NAME}-port-7600.broker
echo ""


