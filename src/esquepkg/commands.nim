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
  let kcatCommand: string = fmt"kcat -L -b {broker}"
  # todo, extract this out and make it a little higher level
  let (output, exitCode) = self.exec(ShellCommand(command: kcatCommand))

  if exitCode != 0:
    # TODO throw an exception instead?
    # should this be part of the shell runCommand stuff?
    # might want a version that quits and a version that just returns
    log fmt"error running command: {kcatCommand}"
    log output
    quit(QuitFailure)

  result = toSeq(topicIterator(output, broker))

# proc findSingleTopic(
#     self: ShellContext, broker: string, topicFilter: string): TopicQueryResult =
#   let topics = getBrokerTopics(self, broker, topicFilter)
#   result = case topics.len:
#     of 0: TopicQueryResult(kind: None)
#     of 1: TopicQueryResult(kind: Single, topic: topics[0])
#     else: TopicQueryResult(kind: Multi, topics: topics)

# proc catTopic(self: ShellContext, broker: string, topicFilter: string) =
#   # we'll want to do something other than just output here...
#   echo "cat topic"


proc runCommand*(self: ShellContext, command: EsqueCommand) =
  # for commands that want a specific topic, we could resolve that first
  # or peel off the commands that don't want a specific topic (env, list, help, partition, version)
  case command.kind:
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
      # let topicQueryResult = findSingleTopic(self, command.env, command.topic)

      let kcatCommand: string = fmt"kcat -C -b {command.env}"
      echo fmt"kcatCommand {kcatCommand}"

when isMainModule:
  let shellContext = buildShellContext()
  shellContext.runCommand(EsqueCommand(kind: List, env: "esque-kafka:9092"))
  shellContext.runCommand(EsqueCommand(kind: Cat, env: "esque-kafka:9092"))
