# `esque` a Kafkaesque tool for working with Kafka
TODO description


# Installation
TODO - run from source instructions

Install `choosenim` with:

    curl https://nim-lang.org/choosenim/init.sh -sSf | sh

# TODO

- change to allow env and broker
- load startup context with overloaded executable locations
- config TOML

## commands still to implement
- Env
- Lag
- List
- MessageAt
- Partition
  - if __consumer_offsets use jvmStringHash, otherwise implement:
  - other hashes:
    - murmur2_32
    - murmur3_32
- Search

## longer term
- work with kafka/librdkafka



#### Config TODO

- parse TOML config file (or json?)
  - this goes in ~/.config/esque
    - https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
    - $XDG_CONFIG_HOME defines the base directory relative to which user-specific configuration files should be stored. If $XDG_CONFIG_HOME is either not set or empty, a default equal to $HOME/.config should be used. 
    - symlinked?
    - allow env variable override?
    - output in verbose? mask passwords?
- certificate passwords?
  - where do they get stored/accessed?


Config examples

`kcat` and the confluent CLI tooling wants something that looks like this
the public and private keys can be in the same file


https://github.com/confluentinc/librdkafka/blob/master/CONFIGURATION.md

Does it also support having the actual inline key?


    security.protocol=ssl
    ssl.ca.location=/path/to/client.pem
    ssl.certificate.location=/path/to/client.pem
    ssl.key.location=/path/to/client.pem
    ssl.key.password=THEPASSWORD


#### Release TODO
- homebrew get osx mac working
  - https://github.com/tednaleid/homebrew-ganda/blob/master/Formula/ganda.rb


## Run Kafka/Zookeeper in docker with certificates using `docker-compose`

need to add this to /etc/hosts (`sudo vi /etc/hosts`):

    127.0.0.1 esque-kafka

We need the host name and not just 127.0.0.1 because the certificates we 
generate need to have a resolvable hostname.  

Generate certificates for the kafka container's use with:

    local-dev/bin/generate-certs.sh

Start docker containers (assuming docker/docker-compose are installed/running):

    docker-compose -f local-dev/docker-compose.yml up -d

look at logs with: 

    docker logs esque-kafka -f

test connectivity to TLS/SSL port 9093 with:

    openssl s_client -connect esque-kafka:9093 -servername esque-kafka

    CONNECTED(00000003)
    depth=0 C = US, ST = MN, L = Minneapolis, O = None, OU = None, CN = esque-kafka
    verify error:num=18:self signed certificate
    verify return:1
    depth=0 C = US, ST = MN, L = Minneapolis, O = None, OU = None, CN = esque-kafka
    verify return:1
    write W BLOCK
    ---
    Certificate chain
    0 s:/C=US/ST=MN/L=Minneapolis/O=None/OU=None/CN=esque-kafka
      i:/C=US/ST=MN/L=Minneapolis/O=None/OU=None/CN=esque-kafka
    ---
    Server certificate
    -----BEGIN CERTIFICATE-----
    MIIDTzCCAjcCFB8P4ShVK42GXLVTpHatMQkhK1DVMA0GCSqGSIb3DQEBCwUAMGQx
    CzAJBgNVBAYTAlVTMQswCQYDVQQIDAJNTjEUMBIGA1UEBwwLTWlubmVhcG9saXMx
    DTALBgNVBAoMBE5vbmUxDTALBgNVBAsMBE5vbmUxFDASBgNVBAMMC2VzcXVlLWth
    ZmthMB4XDTIzMDgxMzIyNDQ0NFoXDTMzMDgxMDIyNDQ0NFowZDELMAkGA1UEBhMC
    VVMxCzAJBgNVBAgTAk1OMRQwEgYDVQQHEwtNaW5uZWFwb2xpczENMAsGA1UEChME
    Tm9uZTENMAsGA1UECxMETm9uZTEUMBIGA1UEAxMLZXNxdWUta2Fma2EwggEiMA0G
    CSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC23116tGOR6lrscAWXZsEuTSUptkdC
    JGKegk1AhpA9pwzURNZOuItgKLtdrYVuJ+toI42nWrEzkfqbM1meNm9Pv1refkl0
    x09JeLxcCii0H/Dm/ndzCIqSriNDMWyu8Kc6uDhGnNC6xyzciREUSbK0XzH1OSsB
    HrizIon3u9IeYrezwnAbhkJl4WKhLokmbpBOs7uC9mVl6JAd9zYEmGyXZxivNN+4
    UUEriwQdGZUG7Iyf11h2gD6OxeVWRWyrUdDlUnZNzH14Mz6MabAn87ViZRtX830I
    gIrDZvh5UMq1LE9o0/xitKJy4dt+uqv4WGTk5l2o+FxCPn02vi/NirWVAgMBAAEw
    DQYJKoZIhvcNAQELBQADggEBAELEqo97PlCCGv8kF288MJkRFYBzZqnnDEoNIvlX
    SF/jPfSuWVVjFX9Qb7yoUb0hy7kZuJlIUy5FQxDtFckOmEXBsai3WnMebZUZUtNG
    nHFuoGFRpqzLdWKoJwj/H+Ed64z6kdJblY4s9vjZnQLlQ9xymmxyrj9vHPd+zERf
    mmJPKHc/iqnPe81JT5Tlq4bQC2LLVkz8/yKUgPG/ziuPExd1zVROK6TIRxOIMcHV
    nRMYKbB8pmYiFecSpCyBEUkMYR5iThWPtbbriNyBUwaHcCQzmA4ZAhhNISW61jc1
    8ft6qJ1U9cEyShrY3imRKbhF+HI8Nontu1lGKvkjAl/Gg+s=
    -----END CERTIFICATE-----
    subject=/C=US/ST=MN/L=Minneapolis/O=None/OU=None/CN=esque-kafka
    issuer=/C=US/ST=MN/L=Minneapolis/O=None/OU=None/CN=esque-kafka
    ---
    No client certificate CA names sent
    Server Temp Key: ECDH, X25519, 253 bits
    ---
    SSL handshake has read 1552 bytes and written 281 bytes
    ---
    New, TLSv1/SSLv3, Cipher is AEAD-CHACHA20-POLY1305-SHA256
    Server public key is 2048 bit
    Secure Renegotiation IS NOT supported
    Compression: NONE
    Expansion: NONE
    No ALPN negotiated
    SSL-Session:
        Protocol  : TLSv1.3
        Cipher    : AEAD-CHACHA20-POLY1305-SHA256
        Session-ID: 
        Session-ID-ctx: 
        Master-Key: 
        Start Time: 1691971573
        Timeout   : 7200 (sec)
        Verify return code: 18 (self signed certificate)
    ---


See if `kcat` can list out the topics on the plaintext port 9092:

    kcat -L -b esque-kafka:9092  

Should emit something like: 

    Metadata for all topics (from broker 1: esque-kafka:9092/1):
    1 brokers:
      broker 1 at esque-kafka:9092 (controller)
    1 topics:
      topic "testtopic" with 1 partitions:
        partition 0, leader 1, replicas: 1, isrs: 1

See if `kcat` can list out the topics on the TLS/SSL port 9093:

    kcat -L -b esque-kafka:9093 \
      -X security.protocol=ssl \
      -X ssl.certificate.location=local-dev/certs/client.pem \
      -X ssl.key.location=local-dev/certs/client.pem \
      -X ssl.ca.location=local-dev/certs/ca.cert 


Should emit something like:

    Metadata for all topics (from broker 1: ssl://esque-kafka:9093/1):
    1 brokers:
      broker 1 at esque-kafka:9093 (controller)
    1 topics:
      topic "testtopic" with 1 partitions:
        partition 0, leader 1, replicas: 1, isrs: 1

To ignore cert checking (if you didn't modify the /etc/hosts file), you can disable hostname checking on `kcat` with:

    -X ssl.endpoint.identification.algorithm=none

### clean up docker-compose containers and create sample topics loaded with data

    local-dev/bin/clean-docker.sh && \
      docker-compose -f local-dev/docker-compose.yml up -d && \
      local-dev/bin/create-topics.sh && \
      local-dev/bin/load-sample-data.sh