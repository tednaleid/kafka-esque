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
  EnvironmentConfig* = ref object
    name*: string
    broker*: string
    port*: int
    topics*: seq[TopicConfig]
  EsqueConfig* = ref object
    # todo, overrides for kcat and other CLI apps?
    environments*: seq[EnvironmentConfig]
    
func `==`(value1, value2: EsqueConfig): bool =
  value1.environments == value2.environments

proc `$`*(self: TopicConfig): string =
  result = fmt"""{self.name}\t{self.broker}:{self.port}\t"""

proc `$`*(self: EnvironmentConfig): string =
  result = @[
    self.name, 
    self.broker & ":" & $self.port
  ].join("\t")

proc `$`*(self: EsqueConfig): string =
  result = $self.environments[0]

proc parseTopicConfig*(table: TomlTableRef): TopicConfig =
  echo ""

proc parseEnvironment*(name: string, envTable: TomlTableRef, envDefaults: EnvironmentConfig): EnvironmentConfig =
  result = EnvironmentConfig( name: name, broker: envDefaults.broker, port: envDefaults.port)
  # TODO only fall back to the default if the value isn't in envTable
  # TODO now we want to extract the topic configs from everything that is a table

proc parseEnvironments*(envTable: TomlTableRef, envDefaults: EnvironmentConfig): seq[EnvironmentConfig] =
  for key, val in envTable:
    # we want all the table elements, those are our environments
    if val.kind == TomlValueKind.Table:
      result.add(parseEnvironment(key, val.getTable(), envDefaults))

proc parseEnvironmentDefaults*(envTable: TomlTableRef): EnvironmentConfig =
  result = EnvironmentConfig()

  # extract the default environment values first, those won't be a table
  for key, val in envTable:
    if val.kind != TomlValueKind.Table:
      case key:
      of "broker":
        result.broker = val.stringVal
      of "port":
        result.port = val.intVal
      else:
        # TODO add property extraction here
        echo "other key: " & key & " val: " & $val

proc parseEsqueConfig*(contents: string): EsqueConfig =
  let toml = parsetoml.parseString(contents)

  # TODO handle case where env doesn't exist
  let envTable = toml.getTable()["env"].getTable()
  let environmentDefaults = parseEnvironmentDefaults(envTable)
  let envs: seq[EnvironmentConfig] = parseEnvironments(envTable, environmentDefaults)
  result = EsqueConfig(environments: envs)

when isMainModule:
  assert $parseEsqueConfig("""
    [env]
    port = 9092
    "security.protocol" = "none"

    [env.local]
    broker = "127.0.0.1"
    [env.dev]
    broker = "10.1.1.10"
    port = 9094

    [env.dev."my-topic"] # allow topic specific configs, conf override/alias
    "security.protocol" = "ssl"
    alias = "topic-prime"
    broker = "kafka-dev.company.com" # can we inherit the broker from the env above?
    port = 9093
    """) != ""

#[

  # check formatting with https://toolkit.site/format.html
  let testConfig = parsetoml.parseString("""
  [env]
  # default properties for all environments?
  port = 9092

  [env.local]
  broker = "127.0.0.1"

  [env.dev]
  broker = "kafka-dev.company.com"
  filter = "myteam-*" # optional topic filter that applies to this environment

  [env.dev."my-topic"] # allow topic specific configs, conf override/alias
  alias = "topic-prime"
  broker = "kafka-dev.company.com" # can we inherit the broker from the env above?
  port = 9093



  # alternatively allow certificate field.  Do we need separate ca location?
  [env.prod]
  broker = "kafka-prod.company.com"
  port = 9093
  certificate = "/path/to/cert.pem" # passwordless, holds public/private/ca cert
  foo.bar.baz = "value"
  """)

  parsetoml.dump(testConfig.getTable())
]#


  #[
    Eventually we'll want to support external config files

    config = "/path/to/my-topic.conf"
    # example contents:
    # security.protocol=ssl
    # ssl.ca.location=/path/to/ca-bundle.crt
    # ssl.certificate.location=/path/to/client.pem
    # ssl.key.location=/path/to/client.pem
    # ssl.key.password=P4$$W0RD
  ]#