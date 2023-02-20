import esquepkg/submodule

let parseResult = parseCliParams()

case parseResult.kind:
  of Completed:
    # TODO parse config here, call a method that finds the file
    # allow it to be overridden with a -f flag from the parseResult?


    let command = parseResult.command
    let shellContext = buildShellContext(command.verbose)
    let exitCode = shellContext.runCommand(command)
    if exitCode == 0:
      quit(QuitSuccess)
    else:
      quit(QuitFailure)
  of StopAndHelp:
    writeHelp(parseResult.command.kind)
    quit(QuitSuccess)
  of Errored:
    writeHelp(parseResult.command.kind, parseResult.message)
    quit(QuitFailure)
  of InProgress:
    writeHelp(parseResult.command.kind, "Error: argument parsing still InProgress")
    quit(QuitFailure)
