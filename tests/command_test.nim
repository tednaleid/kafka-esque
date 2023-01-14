import unittest, sugar, test_common
import esquepkg/shell, esquepkg/commands

func `==`(value1, value2: ShellCommand): bool =
  value1.command == value2.command and value1.args == value2.args

let captureShellStub =
  (s: ShellContext, sc: ShellCommand) => (output: "stubbed!", exitCode: 0)

template captureShellMock(op: string, ec: int, observed: seq[ShellCommand]): untyped =
  (proc (self: ShellContext, shellCommand: ShellCommand): tuple[output: string, exitCode: int] =
    observed.add(shellCommand)
    result = (output: op, exitCode: ec))

let runShellStub = (s: ShellContext, sc: ShellCommand) => 0

template runShellMock(exitCode: int, observed: var seq[ShellCommand]): untyped =
  (proc (self: ShellContext, shellCommand: ShellCommand): int =
    observed.add(shellCommand)
    result = exitCode)

proc shouldRunShell(esqueCommand: EsqueCommand, expectedShell: string) =
  var observed: seq[ShellCommand] = @[]
  let shellContext = buildShellContext(
      true, captureShellStub, runShellMock(0, observed))

  shellContext.runCommand(esqueCommand) === 0

  $observed[0] === expectedShell

suite "command tests":

  test "acl command":
    EsqueCommand(kind: Acls, env: "prod", topic: "item-topic")
      .shouldRunShell "docker run --network host wurstmeister/kafka:2.13-2.8.1 kafka-acls.sh --bootstrap-server prod --topic item-topic --list"

  test "cat command":
    EsqueCommand(kind: Cat, env: "prod", topic: "item-topic", remainingArgs: @["-p", "0"])
      .shouldRunShell "kcat -C -e -q -b prod -t item-topic -p 0"

  test "first command":
    EsqueCommand(kind: First, env: "prod", topic: "item-topic", remainingArgs: @["-p", "0"])
      .shouldRunShell "kcat -C -e -q -b prod -t item-topic -c 1 -p 0"

  test "tail command":
    EsqueCommand(kind: Tail, env: "prod", topic: "item-topic", remainingArgs: @["-p", "0"])
      .shouldRunShell "kcat -C -q -b prod -t item-topic -o end -p 0"


suite "test mocking of functions in the shell context":
  test "we can stub out the capture so that it returns what we want it to":
    let wontBeActuallyRun = ShellCommand(command: "nope", args: @["hello world"])

    let captureShellStub =
      (s: ShellContext, sc: ShellCommand) => (output: "stubbed!", exitCode: 0)
    buildShellContext(true, captureShellStub)
      .capture(wontBeActuallyRun) === (output: "stubbed!", exitCode: 0)

    let failedCaptureCommandStub =
      (s: ShellContext, sc: ShellCommand) => (output: "errored!", exitCode: 1)
    buildShellContext(true, failedCaptureCommandStub)
      .capture(wontBeActuallyRun) === (output: "errored!", exitCode: 1)

  test "we can stub out the run so that it return an exit code":
    let wontBeActuallyRun = ShellCommand(command: "nope", args: @["hello world"])

    buildShellContext(true, captureShellStub, runShellStub)
      .run(wontBeActuallyRun) === 0

    let failedRunShellStub = (s: ShellContext, sc: ShellCommand) => 1

    buildShellContext(true, captureShellStub, failedRunShellStub)
      .run(wontBeActuallyRun) === 1