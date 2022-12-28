
import parseopt

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

proc runCommand*(command: EsqueCommand) =
  echo "Running: " & $command