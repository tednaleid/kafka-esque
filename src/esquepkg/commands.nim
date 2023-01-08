import std/nre except toSeq
import parseopt, strformat, strutils, sequtils
import shell, utils

type
  CommandKind* = enum
    Acls,
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
      of Acls, Cat, Compression, Config, Describe, Env, First, List, Size,
          Tail, Version:
        nil
      of MessageAt:
        partition*: int
        offset*: int
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
    kind*: TopicConfigKind
    broker*: string
    plaintextPort*: int
    securePort*: int
    topic*: string
    # todo TLS stuff
  Topic* = ref object
    name*: string
    broker*: string
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
  let (output, exitCode) = self.exec(kcatCommand)

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

proc catTopic(self: ShellContext, command: EsqueCommand) =
  # we'll want to do something other than just output here...
  echo "cat topic"
  let cmd = self.kcat & @["-C", "-e", "-q", "-b", command.env, "-t", command.topic] & command.remainingArgs
  echo $cmd
  echo self.exec(cmd).output

proc firstTopic(self: ShellContext, command: EsqueCommand) =
  let cmd = self.kcat & @["-C", "-e", "-q", "-b", command.env, "-t", command.topic, "-c", "1"] & command.remainingArgs
  echo $cmd
  echo self.exec(cmd).output

proc runCommand*(self: ShellContext, command: EsqueCommand) =
  # for commands that want a specific topic, we could resolve that first
  # or peel off the commands that don't want a specific topic (env, list, help, partition, version)
  case command.kind:
    of Cat:
      self.catTopic(command)
    of First:
      self.firstTopic(command)
    of Env:
      echo "Running Env " & $command
    of List:
      echo "Running: " & $command
      for topic in getBrokerTopics(self, command.env, command.topic):
        echo topic
    of Partition:
      echo "Running Partition " & $command
    of Version:
      echo "Running Version" & $command
    else:
      echo fmt"TODO {command}"


when isMainModule:
  let shellContext = buildShellContext()
  shellContext.runCommand(EsqueCommand(kind: List, env: "esque-kafka:9092"))
  shellContext.runCommand(EsqueCommand(kind: Cat, env: "esque-kafka:9092", 
    topic: "ten-partitions-lz4",
    remainingArgs: @["-c", "1", "-p", "0"]))
  shellContext.runCommand(EsqueCommand(kind: First, env: "esque-kafka:9092", 
    topic: "ten-partitions-lz4",
    remainingArgs: @["-p", "0", "-f", "'%k %p %o\n'"]))