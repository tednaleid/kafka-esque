import unittest, sugar, test_common
import esquepkg/shell, esquepkg/commands


func `==`(value1, value2: ShellCommand): bool =
  value1.command == value2.command and value1.args == value2.args

let captureShellStub =
  (s: ShellContext, sc: ShellCommand) => (output: "stubbed!", exitCode: 0)

let runShellStub = (s: ShellContext, sc: ShellCommand) => 0

template inlineProc(obs: untyped): untyped =
  (proc(value: string): int =
    obs.add(value)
    result = 0)

# proc captureShellMock(): proc (self: ShellContext, shellCommand: ShellCommand): tuple[output: string, exitCode: int] =
#   var observed: seq[ShellCommand] = @[]
#   return proc (self: ShellContext, shellCommand: ShellCommand): tuple[output: string, exitCode: int] =
#     observed.add(shellCommand)
#     result = (output: "", exitCode: 0)

template captureShellMock(op: string, ec: int, observed: untyped): untyped =
  (proc (self: ShellContext, shellCommand: ShellCommand): tuple[output: string, exitCode: int] =
    observed.add(shellCommand)
    result = (output: op, exitCode: ec))



suite "command tests":
  test "cat command":
    var observed: seq[ShellCommand] = @[]
    var csm = captureShellMock("foobar", 0, observed)

    var shellContext = buildShellContext(true, csm)
    var shellCommand = ShellCommand(command: "foo", args: @["bar"])
    echo csm(shellContext, shellCommand)
    observed === @[shellCommand]

    var csm2 = proc (self: ShellContext, shellCommand: ShellCommand): tuple[output: string, exitCode: int] =
      observed.add(shellCommand) 
      result = (output: "", exitCode: 0)

    var sc2: ShellContext = buildShellContext(true, csm2)
    # var shellContext = buildShellContext(true, csm)
    # var shellContext = buildShellContext()
    # discard shellContext.runCommand(EsqueCommand(kind: Cat, env: "esque-kafka:9092")) 

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