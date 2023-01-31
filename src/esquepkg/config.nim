import parsetoml, strformat, strutils

#[
  Secrets (like PEM certificates and passwords) can be stored in an external file

  example contents, valid for kcat/confluent CLI tooling
  https://github.com/confluentinc/librdkafka/blob/master/CONFIGURATION.md

  external as it'll have a password

      security.protocol=ssl
      ssl.ca.location=/path/to/client.pem
      ssl.certificate.location=/path/to/client.pem
      ssl.key.location=/path/to/client.pem
      ssl.key.password=THEPASSWORD

  # could also have the PEM certificate directly in it with
      ssl.key.pem

]#

type
  TopicConfig* = ref object
    name*: string
    broker*: string
    port*: int
    alias*: string
    certificate*: string
    password*: string
    config*: string
  EnvironmentConfig* = ref object
    name*: string
    broker*: string
    port*: int
    alias*: string
    certificate*: string
    password*: string
    config*: string
    filter*: string
    topics*: seq[TopicConfig]
  EsqueConfig* = ref object
    # todo, overrides for kcat and other CLI apps?
    environments*: seq[EnvironmentConfig]
    

proc `$`*(self: TopicConfig): string =
  result = fmt"""{self.name}\t{self.alias}\t{self.broker}:{self.port}\t"""

proc `$`*(self: EnvironmentConfig): string =
  result = @[
    self.name, 
    self.alias, 
    self.broker & ":" & $self.port
  ].join("\t")

proc `$`*(self: EsqueConfig): string =
  result = $self.environments[0]

proc parseEsqueConfig*(contents: string): EsqueConfig =
  
  let toml = parsetoml.parseString(contents)
  let envs: seq[EnvironmentConfig] = @[EnvironmentConfig(name: "local", broker: "127.0.0.1", port: 9092)]
  result = EsqueConfig(environments: envs)

when isMainModule:
  echo $parseEsqueConfig("""
    [env.local]
    broker = "127.0.0.1"
    port = 9092
    """)


  # check formatting with https://toolkit.site/format.html
  let testConfig = parsetoml.parseString("""
  [env.local]
  broker = "127.0.0.1"
  port = 9092 

  [env.dev]
     # allow multiple brokers, maybe brokers = ["k1.c.c", "k2.c.c"]?
  broker = "kafka-dev.company.com"
  port = 9092 
  filter = "myteam-*" # optional topic filter that applies to this environment

  [env.dev."my-topic"] # allow topic specific configs, conf override/alias
  alias = "topic-prime"
  broker = "kafka-dev.company.com" # can we inherit the broker from the env above?
  port = 9093
  #  holds security stuff
  config = "/path/to/my-topic.conf"

      # example contents:
      # security.protocol=ssl
      # ssl.ca.location=/path/to/client.pem
      # ssl.certificate.location=/path/to/client.pem
      # ssl.key.location=/path/to/client.pem
      # ssl.key.password=P4$$W0RD


  # alternatively allow certificate field.  Do we need separate ca location?
  [env.prod]
  broker = "kafka-prod.company.com"
  port = 9093
  certificate = "/path/to/cert.pem" # passwordless, holds public/private/ca cert
  """)

  # parsetoml.dump(testConfig.getTable())