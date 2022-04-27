#!/bin/bash
set -euf -o pipefail

cd "$(dirname "$0")/../secrets/" || exit

echo "🔖  Generating some fake certificates and other secrets."
echo "⚠️  Remember to type in \"yes\" for all prompts."
sleep 2

TLD="local"
PASSWORD="awesomekafka"

# Generate CA key
openssl req -new -x509 -keyout fake-ca-1.key \
	-out fake-ca-1.crt -days 9999 \
	-subj "/CN=ca1.${TLD}/OU=TS/O=Atos/L=Orleans/S=VIC/C=AU" \
	-passin pass:$PASSWORD -passout pass:$PASSWORD

	# Create keystores
	keytool -genkey -noprompt \
		-alias broker \
		-dname "CN=broker.${TLD}, OU=TS, O=Atos, L=Orleans, S=Centre, C=FR" \
		-keystore kafka.broker.keystore.jks \
		-keyalg RSA \
		-storepass $PASSWORD \
		-keypass $PASSWORD

	# Create CSR, sign the key and import back into keystore
	keytool -keystore kafka.broker.keystore.jks -alias broker -certreq -file broker.csr -storepass $PASSWORD -keypass $PASSWORD

	openssl x509 -req -CA fake-ca-1.crt -CAkey fake-ca-1.key -in broker.csr -out broker-ca1-signed.crt -days 9999 -CAcreateserial -passin pass:$PASSWORD

	keytool -keystore kafka.broker.keystore.jks -alias CARoot -import -file fake-ca-1.crt -storepass $PASSWORD -keypass $PASSWORD

	keytool -keystore kafka.broker.keystore.jks -alias broker -import -file broker-ca1-signed.crt -storepass $PASSWORD -keypass $PASSWORD

	# Create truststore and import the CA cert.
	keytool -keystore kafka.broker.truststore.jks -alias CARoot -import -file fake-ca-1.crt -storepass $PASSWORD -keypass $PASSWORD

	echo $PASSWORD >broker_sslkey_creds
	echo $PASSWORD >broker_keystore_creds
	echo $PASSWORD >broker_truststore_creds
done

echo "✅  All done."
