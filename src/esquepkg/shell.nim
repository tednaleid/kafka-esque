import osproc, utils, strformat

type
  ShellContext* = ref object
    verbose*: bool
    captureShell*: proc(self: ShellContext, shellCommand: ShellCommand):
      tuple[output: string, exitCode: int]
    runShell*: proc(self: ShellContext, shellCommand: ShellCommand): int
    kcat*: ShellCommand
    kafkaConsumerGroups*: ShellCommand
    kafkaTopics*: ShellCommand
    kafkaAcls*: ShellCommand
  ShellCommand* = ref object
    command*: string
    args*: seq[string]

func `$`*(self: ShellCommand): string =
  result = quoteShell(self.command)
  for i in 0..high(self.args):
    result.add(' ')
    result.add(quoteShell(self.args[i]))

func `&`*(originalCommand: ShellCommand, moreArgs: seq[string]): ShellCommand =
  ShellCommand(
    command: originalCommand.command, args: originalCommand.args & moreArgs)

proc verifyExists(exePath: string): bool =
  execCmd(fmt"""command -v "{exePath}" >/dev/null""") == 0

# run the blocking command and hook it up to the current stdout/stderr
# return when the command exits
proc runShell(self: ShellContext, shellCommand: ShellCommand): int =
  if self.verbose: log "+ " & $shellCommand
  result = execCmd($shellCommand)

template run*(self: ShellContext, shellCommand: ShellCommand): int =
  self.runShell(self, shellCommand)

# execute the command and capture both the output and exitCode
# good for limited output situations and when we want to filter/parse the
# output, but not good when it's a potentially infinite stream (like Cat)
proc captureShell(self: ShellContext, shellCommand: ShellCommand):
    tuple[output: string, exitCode: int] =
  if self.verbose: log "+ " & $shellCommand
  result = execCmdEx($shellCommand)

template capture*(self: ShellContext, shellCommand: ShellCommand):
    tuple[output: string, exitCode: int] =
  self.captureShell(self, shellCommand)


const kcatContainer = "edenhill/kcat:1.7.1"

proc kcatCommand(verifyExists: proc(exePath: string): bool): ShellCommand =
  result = if verifyExists("kcat"):
    ShellCommand(command: "kcat", args: @[])
  elif verifyExists("docker"):
    ShellCommand(command: "docker",
      args: @["run", "--network", "host", kcatContainer, "kcat"])
  else:
    when defined(macosx):
      log "'kcat' is required. e.g. brew install kcat"
    else: # assuming linux for now
      log "install kcat or docker"
    raiseAssert "Unable to find 'kcat' executable"


const kafkaContainer = "wurstmeister/kafka:2.13-2.8.1"

proc kafkaShellCommand(verifyExists: proc(exePath: string): bool,
                       baseCommand: string): ShellCommand =
  result = if verifyExists(baseCommand & ".sh"):
    ShellCommand(command: baseCommand & ".sh", args: @[])
  elif verifyExists(baseCommand):
    ShellCommand(command: baseCommand, args: @[])
  elif verifyExists("docker"):
    ShellCommand(command: "docker",
      args: @["run", 
              "--network", 
              "host", 
              kafkaContainer, 
              baseCommand & ".sh"])
  else:
    when defined(macosx):
      log "missing: " & baseCommand & ".sh -> brew install kafka"
    else: # assuming linux for now
      log "install kafka or docker"
    raiseAssert "Unable to find '" & baseCommand & "' executable"
  

proc buildShellContext*(
    verbose: bool = false,
    captureShell: proc (self: ShellContext, shellCommand: ShellCommand): 
      tuple[output: string, exitCode: int] = captureShell,
    runShell: proc(self: ShellContext, shellCommand: ShellCommand): 
      int = runShell,
    verifyExists = verifyExists): ShellContext =

  result = ShellContext(
    verbose: verbose, 
    captureShell: captureShell,
    runShell: runShell, 
    kcat: verifyExists.kcatCommand,
    kafkaConsumerGroups: 
      verifyExists.kafkaShellCommand("kafka-consumer-groups"),
    kafkaTopics: verifyExists.kafkaShellCommand("kafka-topics"),
    kafkaAcls: verifyExists.kafkaShellCommand("kafka-acls"))

when isMainModule:
  let shellCommand = ShellCommand(command: "ls", args: @["-la"])
  let realShellContext = ShellContext(captureShell: captureShell, verbose: true)
  let realResult = realShellContext.capture(shellCommand)
  echo "exitCode: " & $realResult.exitCode
  echo realResult.output

  proc captureShellStub(shellContext: ShellContext, shellCommand: ShellCommand):
      tuple[output: string, exitCode: int] =
    result = (output: "fake output for " & $shellCommand, exitCode: -1)

  let stubbedShellContext = ShellContext(captureShell: captureShellStub)

  let stubbedResult = stubbedShellContext.capture(shellCommand)
  echo "exitCode: " & $stubbedResult.exitCode
  echo stubbedResult.output