import unittest, sugar, test_common
import esquepkg/shell, esquepkg/utils

func `==`(value1, value2: ShellCommand): bool =
  value1.command == value2.command and value1.args == value2.args

suite "shell commands":
  test "shell commands can have more args added and a new one created":
    ShellCommand(command: "kcat", args: @["-L"]) & @["-b", "kafka:9092"] ===
    ShellCommand(command: "kcat", args: @["-L", "-b", "kafka:9092"])

  test "shell commands turned into strings preserve arg grouping":
    $ShellCommand(command: "echo", args: @["first", "the second arg"]) ===
      "echo first 'the second arg'"

  test "default shell context can executing a real echo shell command":
    let context = buildShellContext()
    let echoHelloWorld = ShellCommand(command: "echo", args: @["hello world"])
    context.capture(echoHelloWorld) === (output: "hello world\n", exitCode: 0)


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

    let captureShellStub =
      (s: ShellContext, sc: ShellCommand) => (output: "error!", exitCode: 2)

    let runShellStub = (s: ShellContext, sc: ShellCommand) => 0

    buildShellContext(true, captureShellStub, runShellStub)
      .run(wontBeActuallyRun) === 0

    let failedRunShellStub = (s: ShellContext, sc: ShellCommand) => 1

    buildShellContext(true, captureShellStub, failedRunShellStub)
      .run(wontBeActuallyRun) === 1


