import commands, parseopt, strutils, strformat, os
import utils

proc `$`*(parseResult: ParseResult): string =
  result = case parseResult.kind:
    of Completed, InProgress, StopAndHelp:
      fmt"{parseResult.kind}: {parseResult.command}"
    of Errored:
      fmt"{parseResult.kind}: {parseResult.command} -> {parseResult.message}"

template inProgress(body: untyped) =
  case parseResult.kind:
    of Completed, Errored, StopAndHelp: return parseResult
    of InProgress: return body

proc map(parseResult: ParseResult, transformer: proc(
    pr: ParseResult): ParseResult): ParseResult =
  return case parseResult.kind:
    of Completed, Errored, StopAndHelp: parseResult
    of InProgress: parseResult.transformer()

proc completed(parseResult: ParseResult): ParseResult =
  inProgress: # don't transition if it isn't currently in progress
    ParseResult(kind: Completed, command: parseResult.command)

proc errored(parseResult: ParseResult, message: string): ParseResult =
  inProgress: # don't transition if it isn't currently in progress
    ParseResult(kind: Errored, message: message, command: parseResult.command)

proc stopAndHelp(parseResult: ParseResult): ParseResult =
  inProgress: # don't transition if it isn't currently in progress
    ParseResult(kind: StopAndHelp, command: parseResult.command)

proc setCommand(parseResult: ParseResult, kind: CommandKind): ParseResult =
  inProgress:
    ParseResult(kind: InProgress, remaining: parseResult.remaining,
      command: EsqueCommand(kind: kind))

# kcat commands expect an environment and topic, then remaining flags
# are passed through to the kcat command line app
proc chompKCatParams(parseResult: ParseResult): ParseResult =
  inProgress:
    parseResult.command.remainingArgs = parseResult.remaining.remainingArgs()
    parseResult

template chompArgument(name: string, required: bool, body: untyped) =
  inProgress:
    parseResult.remaining.next()
    case parseResult.remaining.kind:
      of cmdArgument:
        if parseResult.remaining.key == "help":
          parseResult.stopAndHelp()
        else:
          body
          parseResult
      of cmdShortOption, cmdLongOption:
        let normalized = parseResult.remaining.key.normalize()
        case normalized
          of "help", "h", "?":
            parseResult.stopAndHelp()
          else:
            parseResult.errored(
              "Expected <" & name & ">. Found unknown option: " &
                parseResult.remaining.key)
      of cmdEnd:
        if required == true:
          parseResult.errored("Required <" & name & "> argument is missing")
        else:
          parseResult

template chompOptionalArgument(name: string, body: untyped) =
  chompArgument(name, false, body)

template chompRequiredArgument(name: string, body: untyped) =
  chompArgument(name, true, body)

proc chompOptionalEnvironment(parseResult: ParseResult): ParseResult =
  chompOptionalArgument("environment"):
    parseResult.command.env = parseResult.remaining.key

proc chompEnvironment(parseResult: ParseResult): ParseResult =
  chompRequiredArgument("environment"):
    parseResult.command.env = parseResult.remaining.key

proc chompOptionalTopic(parseResult: ParseResult): ParseResult =
  chompOptionalArgument("topic"):
    parseResult.command.topic = parseResult.remaining.key

proc chompTopic(parseResult: ParseResult): ParseResult =
  chompRequiredArgument("topic"):
    parseResult.command.topic = parseResult.remaining.key

proc chompGroupId(parseResult: ParseResult): ParseResult =
  chompRequiredArgument("groupId"):
    parseResult.command.groupId = parseResult.remaining.key

proc chompKey(parseResult: ParseResult): ParseResult =
  chompRequiredArgument("key"):
    parseResult.command.key = parseResult.remaining.key

proc chompPartition(parseResult: ParseResult): ParseResult =
  chompRequiredArgument("partition"):
    # todo gracefully handle non-int values
    parseResult.command.partition = parseResult.remaining.key.parseInt()

proc chompOffset(parseResult: ParseResult): ParseResult =
  chompRequiredArgument("offset"):
    # todo gracefully handle non-int values
    parseResult.command.offset = parseResult.remaining.key.parseInt()

proc chompEnvironmentAndTopic(parseResult: ParseResult): ParseResult =
  inProgress:
    parseResult.chompEnvironment().chompTopic()

let commandKindLookup = prefixTable(CommandKind)

proc parseCliParams*(args: seq[string]): ParseResult =
  var verbose: bool = false

  result = ParseResult(kind: InProgress, remaining: initOptParser(args))

  while result.kind == InProgress:
    result.remaining.next()
    case result.remaining.kind
    of cmdArgument:
      let commandString = result.remaining.key
      let matchResult = commandKindLookup.findMatch(commandString)
      result = case matchResult.kind:
        of None:
          result.setCommand(Help)
            .errored(fmt"Unknown command: {commandString}")
        of Multi:
          result.setCommand(Help)
            .errored(
              fmt"""Ambiguous command: {commandString} - one of {matchResult.values.join(", ")}""")
        of Single:
          case matchResult.value
            of Acls:
              result.setCommand(Acls)
                .chompEnvironmentAndTopic()
                .completed()
            of Cat:
              result.setCommand(Cat)
                .chompEnvironmentAndTopic()
                .chompKCatParams()
                .completed()
            of Compression:
              result.setCommand(Compression)
                .chompEnvironmentAndTopic()
                .completed()
            of Config:
              result.setCommand(Config)
                .chompEnvironmentAndTopic()
                .completed()
            of Describe:
              result.setCommand(Describe)
                .chompEnvironmentAndTopic()
                .completed()
            of Env:
              result.setCommand(Env)
                .chompOptionalEnvironment()
                .chompOptionalTopic()
                .completed()
            of First:
              result.setCommand(First)
                .chompEnvironmentAndTopic()
                .chompKCatParams()
                .completed()
            of Help:
              result.setCommand(Help)
                .stopAndHelp()
            of List:
              result.setCommand(List)
                .chompOptionalEnvironment()
                .chompOptionalTopic()
                .completed()
            of Lag:
              result.setCommand(Lag)
                .chompEnvironmentAndTopic()
                .chompGroupId()
                .completed()
            of MessageAt:
              result.setCommand(MessageAt)
                .chompEnvironmentAndTopic()
                .chompPartition()
                .chompOffset()
                .chompKCatParams()
                .completed()
            of Partition:
              result.setCommand(Partition)
                .chompEnvironmentAndTopic()
                .chompKey()
                .completed()
            of Search:
              result.setCommand(Search)
                .chompEnvironmentAndTopic()
                .chompKey()
                .chompKCatParams()
                .completed()
            of Size:
              result.setCommand(Size)
                .chompEnvironmentAndTopic()
                .completed()
            of Tail:
              result.setCommand(Tail)
                .chompEnvironmentAndTopic()
                .chompKCatParams()
                .completed()
            of Version:
              result.setCommand(Version)
                .completed()

    of cmdLongOption, cmdShortOption:
      let normalized = result.remaining.key.normalize()
      case normalized
        of "help", "h", "?": result = result.setCommand(Help).stopAndHelp()
        of "verbose", "v": verbose = true
        else: result = result.setCommand(Help).errored("Unknown flag: " & normalized)
    of cmdEnd:
      result = result.setCommand(Help).stopAndHelp()

  result.command.verbose = verbose

proc parseCliParams*(): ParseResult =
  return parseCliParams(commandLineParams())

when isMainModule:
  proc showResultOf(args: seq[string]) =
    echo fmt"{args}  ->"
    echo fmt"  {parseCliParams(args)}"

  echo "Bad command:"
  showResultOf(@["foobar"])

  echo "Good commands:"
  showResultOf(@["cat", "prod", "item-topic"])
  showResultOf(@["-v", "cat", "prod", "item-topic", "-p", "0"])
  showResultOf(@["-v", "cat", "--help", "prod", "item-topic", "-p", "0"])
  showResultOf(@["cat", "--verbose"])
  showResultOf(@["cat", "help"])
  showResultOf(@["cat", "--help"])

  showResultOf(@["compression", "dev", "item-topic"])
  showResultOf(@["config", "prod", "event-topic"])
  showResultOf(@["describe", "prod", "event-topic"])
  showResultOf(@["env"])

  showResultOf(@["help"])
  showResultOf(@["--help"])
  showResultOf(@["cat", "help"])
  showResultOf(@["cat", "--help"])

  echo "Ambiguous"
  showResultOf(@["c", "dev", "item-topic"])
