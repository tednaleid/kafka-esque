import commands, strformat, strutils, system/io

const
  esqueVersion* = "0.1.0"

let generalHelp = """
esque - the kafka-esque command line tool

Usage:
  esque [-v] <command> [-h/--help]

Commands:
  esque cat <env> <topic> [remaining args passed to kcat]
  esque compression <env> <topic>
  esque config <env> <topic>
  esque describe <env> <topic>
  esque env
  esque first <env> <topic> [remaining args passed to kcat]
  esque lag <env> <group_id>
  esque list <env> <topic>
  esque message-at <env> <topic> <partition> <offset> [remaining args passed to kcat]
  esque partition <env> <topic> <key>
  esque search <env> <topic> <key> [remaining args passed to kcat]
  esque size <env> <topic>
  esque tail <env> <topic> [remaining args passed to kcat]
  esque version

Command Specific Help:
  esque <command> --help

Options:
  -v --verbose  Verbose output, will emit underlying commands being run on stderr
  -h --help     Show this screen.

Environment Variables:
  ???

Examples:
  ???
"""

# proc getConfigFile() =
#   params.baseDir / "config.toml"

proc helpMessage(commandKind: CommandKind): string =
  return case commandKind:
    of Cat:
      """
Usage: 

  esque cat <env> <topic> [remaining args passed to kcat]
      """
    of Compression:
      """
Usage: 

  esque compression <env> <topic>
      """
    of Config:
      """
Usage: 

  esque config <env> <topic>
      """      
    of Describe:
      """
Usage: 

  esque describe <env> <topic>
      """      
    of Env:
      """
Usage: 

  esque env
      """      
    of First:
      """
Usage: 

  esque first <env> <topic> [remaining args passed to kcat]
      """      
    of Help: generalHelp
    of Lag:
      """
Usage: 

  esque lag <env> <group_id>
      """      
    of List:
      """
Usage: 

  esque list <env> <topic>
      """      
    of MessageAt:
      """
Usage: 

  esque message-at <env> <topic> <partition> <offset> [remaining args passed to kcat]
      """      
    of Partition:
      """
Usage: 

  esque partition <env> <topic> <key>
      """      
    of Search:
      """
Usage: 

  esque search <env> <topic> <key> [remaining args passed to kcat]
      """      
    of Size:
      """
Usage: 

  esque size <env> <topic>
      """      
    of Tail:
      """
Usage: 

  esque tail <env> <topic> [remaining args passed to kcat]
      """      
    of Version:
      """
Usage: 

  esque version
      """      

proc writeHelp*(commandKind: CommandKind, message: string = "") =
  if (message != ""):
    log message & "\n"

  log helpMessage(commandKind)

proc writeVersion() =
  echo("esque v$1 ($2 $3) [$4/$5]" %
       [esqueVersion, CompileDate, CompileTime, hostOS, hostCPU])

when isMainModule:
  writeHelp(Help)
  writeHelp(Cat)
  writeHelp(Cat, "additional information")

  writeVersion()
