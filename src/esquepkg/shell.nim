import osproc, utils

type
  ShellContext* = ref object
    verbose*: bool
    execCommand*: proc(self: ShellContext,
      shellCommand: ShellCommand): tuple[output: string, exitCode: int]
  ShellCommand* = ref object
    command*: string

proc execCommand(self: ShellContext, shellCommand: ShellCommand):
    tuple[output: string, exitCode: int] =
  if self.verbose: log "+ " & shellCommand.command
  result = execCmdEx(shellCommand.command)

template exec*(self: ShellContext, shellCommand: ShellCommand):
    tuple[output: string, exitCode: int] =
  self.execCommand(self, shellCommand)

proc buildShellContext*(verbose: bool = false): ShellContext =
  result = ShellContext(execCommand: execCommand, verbose: verbose)

when isMainModule:
  let shellCommand = ShellCommand(command: "ls -la")
  let realShellContext = ShellContext(execCommand: execCommand, verbose: true)
  let realResult = realShellContext.exec(shellCommand)
  echo "exitCode: " & $realResult.exitCode
  echo realResult.output

  proc execStub(shellContext: ShellContext, shellCommand: ShellCommand): tuple[
      output: string, exitCode: int] =
    result = (output: "fake output for " & shellCommand.command, exitCode: -1)

  let stubbedShellContext = ShellContext(execCommand: execStub)

  let stubbedResult = stubbedShellContext.exec(shellCommand)
  echo "exitCode: " & $stubbedResult.exitCode
  echo stubbedResult.output

