import unittest, test_common
import esquepkg/parse_cli, esquepkg/commands, esquepkg/utils

func `==`(command1, command2: EsqueCommand): bool =
  if command1.kind != command2.kind or
     command1.env != command2.env or
     command1.topic != command2.topic or
     command1.verbose != command2.verbose or
     command1.remainingArgs != command2.remainingArgs: return false
  result = case command1.kind:
    of MessageAt: command1.offset == command2.offset
    else: true

# doesn't compare remaining opt result, our tests don't care about that case
func `==`(result1, result2: ParseResult): bool =
  if result1.kind != result2.kind or
    result1.command != result2.command: return false

  result = case result1.kind:
    of Errored: result1.message == result2.message
    else: true

template `===`(result1, result2: ParseResult) =
  check result1 == result2

proc completed(command: EsqueCommand): ParseResult =
  ParseResult(kind: Completed, command: command)

proc errored(command: EsqueCommand, message: string): ParseResult =
  ParseResult(kind: Errored, command: command, message: message)

proc stopAndHelp(command: EsqueCommand): ParseResult =
  ParseResult(kind: StopAndHelp, command: command)

suite "command argument parsing":

  test "bad options before any command will error and ask for help":
    parseCliParams(@["--badoption", "cat", "prod", "item-topic"]) ===
      errored(EsqueCommand(kind: Help), "Unknown flag: badoption")

  test "no args will show help":
    parseCliParams(@[]) === stopAndHelp(EsqueCommand(kind: Help))

  test "cat with environment and topic":
    parseCliParams(@["cat", "prod", "item-topic"]) ===
      completed(EsqueCommand(
        kind: Cat,
        env: "prod",
        topic: "item-topic"))

  test "cat will save off extra arguments as remainingArgs for kcat usage":
    parseCliParams(@["-v", "cat", "prod", "item-topic", "-p", "0"]) ===
      completed(EsqueCommand(
        kind: Cat,
        env: "prod",
        topic: "item-topic",
        remainingArgs: @["-p", "0"],
        verbose: true))

  test "cat can ask for help specific to cat, ignores later parameters":
    parseCliParams(@["-v", "cat", "--help", "prod", "item-topic", "-p",
        "0"]) ===
      stopAndHelp(EsqueCommand(
        kind: Cat,
        verbose: true))

    test "cat can ask for help as if it were a command":
      parseCliParams(@["cat", "help"]) ===
        stopAndHelp(EsqueCommand(
          kind: Cat))

  test "cat expects an environment not another flag at this point":
    parseCliParams(@["cat", "--verbose"]) ===
      errored(EsqueCommand(kind: Cat),
        "Expected <environment>. Found unknown option: verbose")

  test "cat requires an environment":
    parseCliParams(@["cat"]) ===
      errored(EsqueCommand(kind: Cat),
        "Required <environment> argument is missing")

  test "cat requires a topic":
    parseCliParams(@["cat", "prod"]) ===
      errored(EsqueCommand(kind: Cat, env: "prod"),
        "Required <topic> argument is missing")

  test "compression":
    parseCliParams(@["compression", "dev", "item-topic"]) ===
      completed(EsqueCommand(
        kind: Compression,
        env: "dev",
        topic: "item-topic"))

  test "compression can also ask for help":
    parseCliParams(@["compression", "-h"]) ===
      stopAndHelp(EsqueCommand(
        kind: Compression))

  test "config":
    parseCliParams(@["config", "dev", "item-topic"]) ===
      completed(EsqueCommand(
        kind: Config,
        env: "dev",
        topic: "item-topic"))

  test "describe":
    parseCliParams(@["describe", "dev", "item-topic2"]) ===
      completed(EsqueCommand(
        kind: Describe,
        env: "dev",
        topic: "item-topic2"))

  test "env":
    parseCliParams(@["env"]) === completed(EsqueCommand(kind: Env))

  test "first":
    parseCliParams(@["first", "dev", "item-topic2"]) ===
      completed(EsqueCommand(
        kind: First,
        env: "dev",
        topic: "item-topic2"))

    parseCliParams(@["first", "prod", "sales-topic", "-o", "-1", "-c", "1"]) ===
      completed(EsqueCommand(
        kind: First,
        env: "prod",
        topic: "sales-topic",
        remainingArgs: @["-o", "-1", "-c", "1"]))

  test "help":
    parseCliParams(@["help"]) === stopAndHelp(EsqueCommand(kind: Help))
    parseCliParams(@["--help"]) === stopAndHelp(EsqueCommand(kind: Help))
    parseCliParams(@["-h"]) === stopAndHelp(EsqueCommand(kind: Help))
    parseCliParams(@["-?"]) === stopAndHelp(EsqueCommand(kind: Help))

  test "help ignores later parameters":
    parseCliParams(@["help", "cat"]) === stopAndHelp(EsqueCommand(kind: Help))
    parseCliParams(@["--help", "baz"]) === stopAndHelp(EsqueCommand(kind: Help))
    parseCliParams(@["-h", "foobar"]) === stopAndHelp(EsqueCommand(kind: Help))
    parseCliParams(@["-?", "describe"]) === stopAndHelp(EsqueCommand(kind: Help))

  test "lag requires groupId":
    parseCliParams(@["lag", "dev", "item-topic2", "the-group-id"]) ===
      completed(EsqueCommand(
        kind: Lag,
        env: "dev",
        topic: "item-topic2",
        groupId: "the-group-id"))

    parseCliParams(@["-v", "lag", "dev", "item-topic2", "the-group-id"]) ===
      completed(EsqueCommand(
        kind: Lag,
        verbose: true,
        env: "dev",
        topic: "item-topic2",
        groupId: "the-group-id"))

    parseCliParams(@["lag", "dev", "item-topic2"]) ===
      errored(EsqueCommand(
          kind: Lag, env: "dev", topic: "item-topic2", groupId: "the-group-id"),
        "Required <groupId> argument is missing")

  test "list":
    parseCliParams(@["list", "dev", "item-topic2"]) ===
      completed(EsqueCommand(kind: List, env: "dev", topic: "item-topic2"))

    parseCliParams(@["list", "dev"]) ===
      completed(EsqueCommand(kind: List, env: "dev"))

    parseCliParams(@["list"]) === completed(EsqueCommand(kind: List))

  test "message-at requires partition and offset":
    parseCliParams(@["message-at", "dev", "item-topic2"]) ===
      errored(EsqueCommand(
          kind: MessageAt, env: "dev", topic: "item-topic2"),
        "Required <partition> argument is missing")

    parseCliParams(@["message-at", "dev", "item-topic2", "0"]) ===
      errored(EsqueCommand(
          kind: MessageAt, env: "dev", topic: "item-topic2", partition: 0),
        "Required <offset> argument is missing")

    parseCliParams(@["message-at", "dev", "item-topic2", "0", "1000"]) ===
      completed(EsqueCommand(
          kind: MessageAt, env: "dev", topic: "item-topic2", partition: 0,
          offset: 1_000))

    # todo: test for parsing non-ints for partition/offset

  test "partition requires key":
    parseCliParams(@["partition", "prod", "item-topic"]) ===
      errored(EsqueCommand(
          kind: Partition, env: "prod", topic: "item-topic"),
        "Required <key> argument is missing")

    parseCliParams(@["partition", "prod", "item-topic", "the-key"]) ===
      completed(EsqueCommand(
          kind: Partition, env: "prod", topic: "item-topic", key: "the-key"))

  test "search requires key":
    parseCliParams(@["search", "prod", "item-topic"]) ===
      errored(EsqueCommand(
          kind: Search, env: "prod", topic: "item-topic"),
        "Required <key> argument is missing")

    parseCliParams(@["search", "prod", "item-topic", "the-key"]) ===
      completed(EsqueCommand(
          kind: Search, env: "prod", topic: "item-topic", key: "the-key"))

  test "size":
    parseCliParams(@["size", "dev", "item-topic2"]) ===
      completed(EsqueCommand(kind: Size, env: "dev", topic: "item-topic2"))

  test "tail allows args to pass to kcat":
    parseCliParams(@["tail", "dev", "item-topic2"]) ===
      completed(EsqueCommand(kind: Tail, env: "dev", topic: "item-topic2"))

    parseCliParams(@["tail", "dev", "item-topic2", "-c", "10"]) ===
      completed(EsqueCommand(
        kind: Tail, env: "dev", topic: "item-topic2",
        remainingArgs: @["-c", "10"]))

  test "version":
    parseCliParams(@["version"]) ===
      completed(EsqueCommand(kind: Version))

  test "unknown command shows help":
    parseCliParams(@["foobar"]) ===
      errored(EsqueCommand(kind: Help), "Unknown command: foobar")

  test "a command can be found if it has a unique prefix":
    parseCliParams(@["desc", "dev", "item-topic2"]) ===
      completed(EsqueCommand(
        kind: Describe, env: "dev", topic: "item-topic2"))

  test "a non-unique prefix will echo possible commands":
    parseCliParams(@["c"]) ===
      errored(EsqueCommand(kind: Help), "Ambiguous command: c - one of Cat, Compression, Config")

  test "a command with a kebob-case hyphen in it can be found before the hyphen":
    parseCliParams(@["message", "dev", "item-topic2", "0", "1000"]) ===
      completed(EsqueCommand(
          kind: MessageAt, env: "dev", topic: "item-topic2", partition: 0,
          offset: 1_000))
