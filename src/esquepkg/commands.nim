import std/nre except toSeq
import parseopt, strformat, strutils, sequtils
import shell, utils

type
  CommandKind* = enum
    Acls, Cat, Compression, Config, Describe, Env, First, Help, Lag, List,
    MessageAt, Partition, Search, Size, Tail, Version
  EsqueCommand* = object
    env*, topic*: string
    verbose*: bool
    remainingArgs*: seq[string]
    case kind*: CommandKind
      of Acls, Cat, Compression, Config, Describe, Env, First, List, Size,
          Tail, Version:
        nil
      of MessageAt:
        partition*, offset*: int
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
  TopicConfigKind* = enum
    Plaintext, Secure
  TopicConfig* = ref object
    broker*, topic*: string
    kind*: TopicConfigKind
    plaintextPort*, securePort*: int
    # todo TLS stuff
  Topic* = ref object
    name*, broker*: string
    partitions*: int

proc `$`*(topic: Topic): string =
  result = fmt"{topic.name} on {topic.broker} has {$topic.partitions} partitions"

let topicRegex = re"""topic "(.*)" with (\d+) partitions:"""

iterator topicIterator(kcatOutput: string, broker: string): Topic =
  for topicMatch in kcatOutput.findIter(topicRegex):
    let matchSeq = topicMatch.captures.toSeq
    yield Topic(
      name: matchSeq[0].get,
      broker: broker,
      partitions: matchSeq[1].get.parseInt)

proc getBrokerTopics(
    self: ShellContext, broker: string, topicFilter: string): seq[Topic] =

  let kcatCommand = self.kcat & @["-L", "-b", broker]
  let (output, exitCode) = self.capture(kcatCommand)

  if exitCode != 0:
    # TODO throw an exception instead?
    # should this be part of the shell runCommand stuff?
    # might want a version that quits and a version that just returns
    log fmt"error running command: {kcatCommand}"
    log output
    quit(QuitFailure)

  result = toSeq(topicIterator(output, broker))

proc findSingleTopic(
    self: ShellContext, broker: string, topicFilter: string): MatchResult =
  let topics = getBrokerTopics(self, broker, topicFilter)
  result = case topics.len:
    of 0: MatchResult(kind: None)
    of 1: MatchResult(kind: Single, topic: topics[0])
    else: MatchResult(kind: Multi, topics: topics)

proc topicAcls(self: ShellContext, command: EsqueCommand): int =
  let kafkaAcls = self.kafkaAcls & 
                  @["--bootstrap-server", 
                    command.env, 
                    "--topic", 
                    command.topic,
                    "--list"
                  ] & command.remainingArgs
  result = self.run(kafkaAcls)

proc catTopic(self: ShellContext, command: EsqueCommand): int =
  let kcatCat = self.kcat & @["-C", "-e", "-q", "-b", command.env, "-t",
      command.topic] & command.remainingArgs
  result = self.run(kcatCat)

proc firstTopic(self: ShellContext, command: EsqueCommand): int =
  let kcatFirst = self.kcat & @["-C", "-e", "-q", "-b", command.env, "-t",
      command.topic, "-c", "1"] & command.remainingArgs
  result = self.run(kcatFirst)

proc tailTopic(self: ShellContext, command: EsqueCommand): int =
  let kcatFirst = self.kcat & @["-C", "-q", "-b", command.env, "-t",
      command.topic, "-o", "end"] & command.remainingArgs
  result = self.run(kcatFirst)

proc runCommand*(self: ShellContext, command: EsqueCommand): int =
  # for commands that want a specific topic, we could resolve that first
  # or peel off the commands that don't want a specific topic (env, list, help, partition, version)
  result = case command.kind:
    of Acls: self.topicAcls(command)
    of Cat: self.catTopic(command)
    of Compression: 0
    of Config: 0
    of Describe: 0
    of Env: 0
    of First: self.firstTopic(command)
    of Help: 0
    of Lag: 0
    of List:
      # TODO switch this so it emits alternate format
      for topic in getBrokerTopics(self, command.env, command.topic): echo topic
      0
    of MessageAt: 0
    of Partition: 0
    of Search: 0
    of Size: 0
    of Tail: self.tailTopic(command)
    of Version: 0


when isMainModule:
  var shellContext = buildShellContext(true)
  discard shellContext.runCommand(
    EsqueCommand(kind: Acls, 
                 env: "esque-kafka:9092", 
                 topic: "ten-partitions-lz4")) 
  discard shellContext.runCommand(
    EsqueCommand(kind: Cat, 
                 env: "esque-kafka:9092",
                 topic: "ten-partitions-lz4",
                 remainingArgs: @["-c", "1", "-p", "0"]))
  discard shellContext.runCommand(EsqueCommand(kind: First, env: "esque-kafka:9092",
    topic: "ten-partitions-none",
    remainingArgs: @["-p", "0", "-f", "%k %p %o\n"]))
  discard shellContext.runCommand(EsqueCommand(kind: List, env: "esque-kafka:9092")) 