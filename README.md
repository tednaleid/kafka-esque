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

    openssl s_client -debug -connect localhost:9093 -tls1

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

### clean up docker-compose containers and create sample topics loaded with data

    local-dev/bin/clean-docker.sh && \
      docker-compose -f local-dev/docker-compose.yml up -d && \
      local-dev/bin/create-topics.sh && \
      local-dev/bin/load-sample-data.sh