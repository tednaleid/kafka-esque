import std/nre except toSeq
import parseopt, os, osproc, strformat, strutils, sequtils, parseopt

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
  Topic* = ref object
    name*: string
    broker*: string
    partitions*: int

proc log*(msg: string): void =
  stderr.writeLine(msg)

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


proc getBrokerTopics(broker: string, topicFilter: string): seq[Topic] =
  # TODO get the appropriate kcat command and connection context, ConcreteArgs method?
  let kcatCommand: string = fmt"kcat -L -b {broker}"
  let (output, exitCode) = execCmdEx(kcatCommand)

  if exitCode != 0:
    # TODO throw an exception instead?
    log fmt"error running command: {kcatCommand}"
    log output
    quit(QuitFailure)
    
  result = toseq(topicIterator(output, broker))

proc runCommand*(command: EsqueCommand) =
  case command.kind:
    of Cat:
      # want to list first to find the actual topic name and ensure it's a single
      echo "Running: " & $command
      # let returnCode = execCmd(command)
      # log returnCode

    of List:
      echo "Running: " & $command
      for topic in getBrokerTopics(command.env, command.topic):
        echo topic

      

    else:
      echo "Running: " & $command


when isMainModule:
  runCommand(EsqueCommand(kind: List, env: "esque-kafka:9092"))