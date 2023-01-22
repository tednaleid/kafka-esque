import unittest, sugar, sequtils, test_common
import esquepkg/shell, esquepkg/commands

func `==`(value1, value2: ShellCommand): bool =
  value1.command == value2.command and value1.args == value2.args

func `==`(value1, value2: TopicPartition): bool =
  value1.brokerId == value2.brokerId and 
    value1.topic == value2.topic and
    value1.partition == value2.partition and
    value1.size == value2.size and
    value1.offsetLag == value2.offsetLag

let captureShellStub =
  (s: ShellContext, sc: ShellCommand) => (output: "stubbed!", exitCode: 0)

template captureShellMock(emitStdout: string, code: int, observed: seq[ShellCommand]): untyped =
  (proc (self: ShellContext, shellCommand: ShellCommand): tuple[output: string, exitCode: int] =
    observed.add(shellCommand)
    result = (output: emitStdout, exitCode: code))

proc shouldCaptureShell(esqueCommand: EsqueCommand, 
                        expectedShell: string,
                        emitStdout: string) =
  var observed: seq[ShellCommand] = @[]
  let shellContext = 
    buildShellContext(true, captureShellMock(emitStdout, 0, observed))
  shellContext.runCommand(esqueCommand) === 0
  $observed[0] === expectedShell

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

  test "config command":
    let willEmit = """
Topic: item-topic PartitionCount: 3	ReplicationFactor: 3	Configs: message.downconversion.enable=true,min.insync.replicas=2,cleanup.policy=compact,delete,segment.bytes=1073741824,retention.ms=1814400000,flush.messages=10000,message.format.version=2.7-IV2,max.message.bytes=1000012,min.compaction.lag.ms=0,min.cleanable.dirty.ratio=0.5,unclean.leader.election.enable=false,retention.bytes=-1,delete.retention.ms=86400000
	Topic: item-topic Partition: 0	Leader: 27	Replicas: 27,56,57	Isr: 57,27,56
	Topic: item-topic Partition: 1	Leader: 28	Replicas: 28,57,58	Isr: 58,57,28
	Topic: item-topic Partition: 2	Leader: 29	Replicas: 29,58,59	Isr: 29,58,59  
  """
    EsqueCommand(kind: Config, env: "prod", topic: "item-topic")
      .shouldCaptureShell(
        "docker run --network host wurstmeister/kafka:2.13-2.8.1 kafka-topics.sh --bootstrap-server prod --topic item-topic --describe", 
        willEmit)

  test "compression command":
    let willEmit = """
%7|1673909882.526|FETCH|rdkafka#consumer-1| [thrd:esque-kafka:9092/bootstrap]: esque-kafka:9092/1: Topic ten-partitions-lz4 [9] in state active at offset 99999 (0/100000 msgs, 0/65536 kb queued, opv 2) is fetchable
%7|1673909882.527|CONSUME|rdkafka#consumer-1| [thrd:esque-kafka:9092/bootstrap]: esque-kafka:9092/1: Enqueue 1 message(s) (1374 bytes, 1 ops) on ten-partitions-lz4 [0] fetch queue (qlen 0, v2, last_offset 99999, 0 ctrl msgs, 0 aborted msgsets, lz4)
%7|1673909882.527|FETCH|rdkafka#consumer-1| [thrd:esque-kafka:9092/bootstrap]: esque-kafka:9092/1: Fetch topic ten-partitions-lz4 [0] at offset 100000 (v2)
    """
    EsqueCommand(kind: Compression, env: "prod", topic: "item-topic")
      .shouldCaptureShell "kcat -C -e -q -b prod -t item-topic -c 1 -d fetch", willEmit

  test "first command":
    EsqueCommand(kind: First, env: "prod", topic: "item-topic", remainingArgs: @["-p", "0"])
      .shouldRunShell "kcat -C -e -q -b prod -t item-topic -c 1 -p 0"

  test "tail command":
    EsqueCommand(kind: Tail, env: "prod", topic: "item-topic", remainingArgs: @["-p", "0"])
      .shouldRunShell "kcat -C -q -b prod -t item-topic -o end -p 0"

  test "version command":
    buildShellContext().runCommand(EsqueCommand(kind: Version)) === 0

  test "extract configs from kafka-topic output":
    let describeTopicOutput = """
Topic: item-topic PartitionCount: 3	ReplicationFactor: 3	Configs: message.downconversion.enable=true,min.insync.replicas=2,cleanup.policy=compact,delete,segment.bytes=1073741824,retention.ms=1814400000,flush.messages=10000,message.format.version=2.7-IV2,max.message.bytes=1000012,min.compaction.lag.ms=0,min.cleanable.dirty.ratio=0.5,unclean.leader.election.enable=false,retention.bytes=-1,delete.retention.ms=86400000
	Topic: item-topic Partition: 0	Leader: 27	Replicas: 27,56,57	Isr: 57,27,56
	Topic: item-topic Partition: 1	Leader: 28	Replicas: 28,57,58	Isr: 58,57,28
	Topic: item-topic Partition: 2	Leader: 29	Replicas: 29,58,59	Isr: 29,58,59  
    """

    let configs = describeTopicOutput.parseConfig.toSeq 
    configs === @[
      (key: "message.downconversion.enable", value: "true"),
      (key: "min.insync.replicas", value: "2"),
      (key: "cleanup.policy", value: "compact,delete"),
      (key: "segment.bytes", value: "1073741824"),
      (key: "retention.ms", value: "1814400000"),
      (key: "flush.messages", value: "10000"),
      (key: "message.format.version", value: "2.7-IV2"),
      (key: "max.message.bytes", value: "1000012"),
      (key: "min.compaction.lag.ms", value: "0"),
      (key: "min.cleanable.dirty.ratio", value: "0.5"),
      (key: "unclean.leader.election.enable", value: "false"),
      (key: "retention.bytes", value: "-1"),
      (key: "delete.retention.ms", value: "86400000")]

  test "parse size json into iterator":
    let logDirsOutput = """Querying brokers for log directories information
Received log directory information from brokers 1
{"version":1,"brokers":[{"broker":1,"logDirs":[{"logDir":"/kafka/kafka-logs-d618b5e05bb4","error":null,"partitions":[{"partition":"ten-partitions-lz4-9","size":4427587,"offsetLag":0,"isFuture":false},{"partition":"ten-partitions-lz4-8","size":4428004,"offsetLag":0,"isFuture":false}]}]}]}
"""
    let topicPartitions = logDirsOutput.topicPartitions.toSeq
    topicPartitions === @[
      TopicPartition(brokerId: 1, topic: "ten-partitions-lz4", partition: 9, size: 4427587),
      TopicPartition(brokerId: 1, topic: "ten-partitions-lz4", partition: 8, size: 4428004)]

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