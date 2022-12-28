# `esque` a Kafkaesque tool for working with Kafka

TODO description


# Installation


TODO - run from source instructions

Install `choosenim` with:

    curl https://nim-lang.org/choosenim/init.sh -sSf | sh

# TODO

- get docker based commands working
- get kcat commands working

- work with kafka/librdkafka
- copy over docker-compose/tls cert stuff from other kafka-esque


#### Implement Features TODO
- Cat
- Compression
- Config
- Describe
- Env
- First
- X Help
  - X implement command specific help
- Lag
- List
- MessageAt
- Partition
  - if __consumer_offsets use jvmStringHash, otherwise implement:
  - other hashes:
    - murmur2_32
    - murmur3_32
- Search
- Size
- Tail
- Version

#### Config TODO

- create context object that has:
  - kcat command seq, examples:
    - kcat
    - /direct/path/to/kcat
    - docker run edenhill/kcat:1.7.1 kcat
- parse TOML config file (or json?)
  - this goes in ~/.config/esque
    - symlinked?
    - allow env variable override
- certificate passwords?
  - where do they get stored/accessed?


#### Release TODO
- homebrew get osx mac working
  - https://github.com/tednaleid/homebrew-ganda/blob/master/Formula/ganda.rb