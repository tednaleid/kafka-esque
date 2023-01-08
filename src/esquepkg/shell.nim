import osproc, utils, strformat, strutils

type
  ShellContext* = ref object
    verbose*: bool
    execCommand*: proc(self: ShellContext, shellCommand: ShellCommand): 
      tuple[output: string, exitCode: int]
    kcat*: ShellCommand
    kafkaConsumerGroups*: ShellCommand
    kafkaTopics*: ShellCommand
    kafkaAcls*: ShellCommand
  ShellCommand* = ref object
    command*: seq[string]

proc `$`*(self: ShellCommand): string = $self.command

proc `&`*(originalCommand: ShellCommand, moreArgs: seq[string]): ShellCommand =
  ShellCommand(command: originalCommand.command & moreArgs)

proc verifyExists(exePath: string): bool = 
  execCmd(fmt"""command -v "{exePath}" 2>&1""") == 0

proc execCommand(self: ShellContext, shellCommand: ShellCommand):
    tuple[output: string, exitCode: int] =
  # TODO switch this to the version that takes a seq
  if self.verbose: log "+ " & shellCommand.command.join(" ")
  result = execCmdEx(shellCommand.command.join(" "))

template exec*(self: ShellContext, shellCommand: ShellCommand):
    tuple[output: string, exitCode: int] =
  self.execCommand(self, shellCommand)

proc kcatCommand(verifyExists: proc(exePath: string): bool): ShellCommand = 
  result = if verifyExists("kcat"):
    ShellCommand(command: @["kcat"])
  elif verifyExists("docker"):
    ShellCommand(command: @["docker", "run", "edenhill/kcat:1.7.1", "kcat"])
  else: 
    when defined(macosx):
      log "'kcat' is required. e.g. brew install kcat"
    else: # assuming linux for now
      log "install kcat or docker"
    raiseAssert "Unable to find 'kcat' executable"


proc buildShellContext*(
  verbose: bool = false,
  verifyExists: proc(exePath: string): bool = verifyExists,
  execCommand = execCommand): ShellContext =

  # todo verify that we've got the right executables here and stick them in the context
  # later we can potentially build things up from config


  # TODO start here, see if we get kcat like we want and that we can then call it

  result = ShellContext( 
    verbose: verbose, 
    execCommand: execCommand,
    kcat: verifyExists.kcatCommand)

when isMainModule:
  let shellCommand = ShellCommand(command: @["ls", "-la"])
  let realShellContext = ShellContext(execCommand: execCommand, verbose: true)
  let realResult = realShellContext.exec(shellCommand)
  echo "exitCode: " & $realResult.exitCode
  echo realResult.output

  proc execStub(shellContext: ShellContext, shellCommand: ShellCommand): 
      tuple[output: string, exitCode: int] =
    result = (output: "fake output for " & shellCommand.command.join(" "), 
      exitCode: -1)

  let stubbedShellContext = ShellContext(execCommand: execStub)

  let stubbedResult = stubbedShellContext.exec(shellCommand)
  echo "exitCode: " & $stubbedResult.exitCode
  echo stubbedResult.output

