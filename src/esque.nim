import esquepkg/submodule

let parseResult = parseCliParams()

# todo, create the ShellContext that knows where apps are and how they should be run

case parseResult.kind:
  of Completed:
    let shellContext = buildShellContext()
    shellContext.runCommand(parseResult.command)
    quit(QuitSuccess)
  of StopAndHelp:
    writeHelp(parseResult.command.kind)
    quit(QuitSuccess)
  of Errored:
    writeHelp(parseResult.command.kind, parseResult.message)
    quit(QuitFailure)
  of InProgress:
    writeHelp(parseResult.command.kind, "Error: argument parsing still InProgress")
    quit(QuitFailure)
