
import parseopt, os, osproc

type
  CommandKind* = enum
    Cat,
    Compression,
    Config,
    Describe,
    Env,
    First,
    Help,
    Lag,
    List,
    MessageAt,
    Partition,
    Search,
    Size,
    Tail,
    Version
  EsqueCommand* = object
    env*: string
    topic*: string
    verbose*: bool
    remainingArgs*: seq[string]
    case kind*: CommandKind
      of Cat, First, Tail:
        nil
      of MessageAt:
        partition*: int
        offset*: int
      of Compression, Config, Describe, Env, List, Size, Version:
        nil
      of Help:
        message*: string
      of Lag:
        groupId*: string
      of Partition, Search:
        key*: string
  ParseResultKind* = enum
    InProgress, Completed, Errored, StopAndHelp
  ParseResult* = ref object
    command*: EsqueCommand
    case kind*: ParseResultKind
      of InProgress:
        remaining*: OptParser
      of Errored:
        message*: string
      of Completed, StopAndHelp: nil
  ConcreteArgs* = ref object
    kind*: ParseResultKind
    broker*: string
    topic*: string
    execute*: seq[string]
  TopicConfigKind* = enum
    Plaintext, Secure
  TopicConfig* = ref object
    kind*: TopicConfigKind
    broker*: string
    plaintextPort*: int
    securePort*: int
    topic*: string
    # todo TLS stuff

proc log*(msg: string): void =
  stderr.writeLine(msg)

proc resolveBroker(command: EsqueCommand, concreteArgs: ConcreteArgs): ConcreteArgs =
  # todo make this really get the broker, return an either/optional?
  return new(ConcreteArgs)

proc resolveTopic(command: EsqueCommand): ConcreteArgs =
  # todo make this really get the topic, return an either/optional?
  return new(ConcreteArgs)

proc listTopics(): seq[string] =
  log "list topics"

iterator topicConfigs(env: string = "", topicFilter: string = ""): string = 
  # env is optional
  # this could be an iterator that yields topic config values
  # topic config is broker, topic, tls certificate info
  log "list topics"

proc listTopicsCommand(): seq[string] =
  log "list topics command"

proc runCommand*(command: EsqueCommand) =
  case command.kind:
    of Cat:
      # want to list first to find the actual topic name and ensure it's a single
      echo "Running: " & $command
      # let returnCode = execCmd(command)
      # log returnCode

    of List:
      echo "Running: " & $command

    else:
      echo "Running: " & $command