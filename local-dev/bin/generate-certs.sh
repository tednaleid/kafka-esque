#! /usr/bin/env bash

# generates Kafka Server and Client certificates with a common Certificate Authority (CA) that the server is configured to trust

# high-level steps:
# 1. Create Certificate Authority that will be used to sign all certificates
# 2. Create a Truststore that has the CA in it that kafka will use to ensure that clients are using trusted certificates
# 3. Create a Server keystore (JKS) that has a certificate for the server that is signed by the CA and also has the CA in it
# 4. Create a Client keystore (JKS) that has the client's certificate that is signed by the CA
# 5. Export a Client PEM (PKCS12, not password protected) file from the client keystore

set -euxo pipefail

command -v keytool >/dev/null 2>&1 || { echo "'keytool' is required to generate certs, it is part of the Java JDK" >&2; exit 1; }
command -v openssl >/dev/null 2>&1 || { echo "'openssl' is required to generate certs" >&2; exit 1; }


BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERT_DIR="${BIN_DIR}/../certs"

SSL_PASSWORD=changeit

CA_HOSTNAME="esque-kafka"
CA_KEY="$CERT_DIR/ca.key"
CA_CERT="$CERT_DIR/ca.cert"

KEY_SIZE=2048
DAYS_VALID=3650

function create_certificate_authority_keypair {
    ## create a Certificate Authority (CA) key pair that can sign the server and client certificates, we'll use the same CA for both
    openssl req -new -sha256 -newkey rsa:$KEY_SIZE -x509 -days $DAYS_VALID \
       -keyout $CA_KEY -out $CA_CERT -passout pass:$SSL_PASSWORD \
       -subj "/C=US/ST=MN/L=Minneapolis/O=None/OU=None/CN=${CA_HOSTNAME}"
}

function create_CA_truststore {
    ## add CA public cert to truststore that is used by the server to determine which CAs to trust
    SERVER_TRUSTSTORE_JKS="$CERT_DIR/kafka.server.truststore.jks"
    keytool -keystore $SERVER_TRUSTSTORE_JKS -alias CARoot -import -file $CA_CERT -storepass $SSL_PASSWORD -noprompt
}

function create_CA_signed_keystore {
    local key_alias=$1
    local hostname=$2
    local keystore=$3
    local csr_file=$4
    local signed_file=$5

    ## create keystore (jks) with public/private key
    keytool -keystore $keystore \
            -alias $key_alias -validity $DAYS_VALID -genkey -keyalg RSA -keysize $KEY_SIZE \
            -storepass $SSL_PASSWORD -keypass $SSL_PASSWORD \
            -dname "CN=${hostname}, OU=None, O=None, L=Minneapolis, ST=MN, C=US"

    ## export the cert so it can be signed
    keytool -keystore $keystore -alias $key_alias -certreq -file $csr_file -storepass $SSL_PASSWORD -noprompt

    ## sign it with the CA
    openssl x509 -req -sha256 -CA $CA_CERT -CAkey $CA_KEY -in $csr_file -out $signed_file -days $DAYS_VALID -CAcreateserial -passin pass:$SSL_PASSWORD

    ## import the CA and the certificate that it just signed into the keystore
    keytool -keystore $keystore -alias CARoot -import -file $CA_CERT -storepass $SSL_PASSWORD -noprompt
    keytool -keystore $keystore -alias $key_alias -import -file $signed_file -storepass $SSL_PASSWORD -noprompt
}

function export_pem_keypair_without_password  {
    local jks_keystore=$1
    local pkcs12_keystore=$2
    local pem_file=$3

    ## Copy JKS format keystore to PKCS12 format
    keytool -importkeystore -srckeystore $jks_keystore -destkeystore $pkcs12_keystore -srcstoretype JKS -deststoretype PKCS12 -srcstorepass $SSL_PASSWORD -deststorepass $SSL_PASSWORD -noprompt

    ## export PEM (non-password protected) file for `kit` client use
    openssl pkcs12 -in $pkcs12_keystore -out $pem_file -nodes -passin pass:$SSL_PASSWORD
}

echo "removing old certs"

mkdir -p $CERT_DIR
rm -rf $CERT_DIR/*

# Certificate Authority
create_certificate_authority_keypair

# Server Truststore
create_CA_truststore

# Server Keystore used by Kafka
SERVER_HOSTNAME="127.0.0.1.xip.io"
SERVER_KEYSTORE_JKS="$CERT_DIR/kafka.server.keystore.jks"
SERVER_CSR="$CERT_DIR/server-csr"
SERVER_CERT_SIGNED="$CERT_DIR/server-cert-signed"
create_CA_signed_keystore "server" $SERVER_HOSTNAME $SERVER_KEYSTORE_JKS $SERVER_CSR $SERVER_CERT_SIGNED

# Create the client's keystore with a key that has been signed by a CA that the Kafka server trusts
CLIENT_HOSTNAME="localhost"
CLIENT_KEYSTORE_JKS="$CERT_DIR/kafka.client.keystore.jks"
CLIENT_CSR="$CERT_DIR/client-csr"
CLIENT_CERT_SIGNED="$CERT_DIR/client-cert-signed"
create_CA_signed_keystore "client" $CLIENT_HOSTNAME $CLIENT_KEYSTORE_JKS $CLIENT_CSR $CLIENT_CERT_SIGNED

# Export non-password protected key pair for use by client
CLIENT_KEYSTORE_P12="$CERT_DIR/kafka.client.keystore.p12"
CLIENT_PEM_FILE="$CERT_DIR/client.pem"
export_pem_keypair_without_password $CLIENT_KEYSTORE_JKS $CLIENT_KEYSTORE_P12 $CLIENT_PEM_FILE

ls $CERT_DIR

echo after "docker-compose up" you can test the connectivity with
echo openssl s_client -debug -connect localhost:9093 -tls1

