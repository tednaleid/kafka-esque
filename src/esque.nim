import esquepkg/submodule

let parseResult = parseCliParams()

case parseResult.kind:
  of Completed:
    let command = parseResult.command
    let shellContext = buildShellContext(command.verbose)
    let exitCode = shellContext.runCommand(command)
    quit(exitCode)
  of StopAndHelp:
    writeHelp(parseResult.command.kind)
    quit(QuitSuccess)
  of Errored:
    writeHelp(parseResult.command.kind, parseResult.message)
    quit(QuitFailure)
  of InProgress:
    writeHelp(parseResult.command.kind, "Error: argument parsing still InProgress")
    quit(QuitFailure)
