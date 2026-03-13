#!/bin/sh

if [ "$#" -ne 1 ]
then
  echo "Usage: Must supply a domain."
  exit 1
fi

DOMAIN=$1

FILE=ca.key
if [ -f "$FILE" ]; then
    echo "Using existing CA private key"
else
    # Generate the private key for the CA:
    echo "Generating the private key for the CA"
    echo "Take note of the private key pass phrase"
    openssl genrsa -des3 -out ca.key 2048 #Take note of the PEM password
fi

FILE=ca.pem
if [ -f "$FILE" ]; then
    echo "using existing CA certificate"
else
    # Next, we generate a root certificate
    echo "Generating a root certificate"
    echo "When asked for the Common Name  use $DOMAIN"
    openssl req -x509 -new -nodes -key ca.key -sha256 -days 1825 -out ca.pem
fi

# Create a private key for the dev site:
echo "Generating a private key for the $DOMAIN dev site"
openssl genrsa -out $DOMAIN.key 2048

echo "Generating a CSR for $DOMAIN"
echo "When asked for the Common Name use $DOMAIN"
openssl req -new -key $DOMAIN.key -out $DOMAIN.csr #No password

cat > $DOMAIN.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = $DOMAIN
EOF

#Next run the command to create the certificate: using our CSR, the CA private key, the CA certificate, and the config file:
echo "Generating a certificate for $DOMAIN"
openssl x509 -req -in $DOMAIN.csr -CA ca.pem -CAkey ca.key \
-CAcreateserial -out $DOMAIN.crt -days 825 -sha256 -extfile $DOMAIN.ext

echo "Dont forget to add the CA certificate to your keychain"
