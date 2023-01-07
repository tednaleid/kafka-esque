import strutils, tables
import std/nre except toSeq

type
  MatchResultKind* = enum
    None, Single, Multi
  MatchResult*[T] = ref object
    case kind*: MatchResultKind
      of None: nil
      of Single: value*: T
      of Multi: values*: seq[T]

proc log*(msg: string): void =
  stderr.writeLine(msg)

proc `$`*(matchResult: MatchResult): string =
  result = case matchResult.kind
    of None: "None"
    of Single: $matchResult.value
    of Multi: $matchResult.values


proc toKebabCase*(orig: string): string =
  result = orig.replace(re"([a-z0–9])([A-Z])",
    proc(match: RegexMatch): string =
    return match.captures[0] & "-" & match.captures[1]
  ).toLower

when isMainModule:
  assert "ToKebabCase".toKebabCase == "to-kebab-case"

# given an Enum, create a prefix table that maps strings to the enum values
# that start with that prefix
proc prefixTable*[T: enum](enumType: typedesc[T]): Table[string, seq[T]] =
  for e in enumType:
    let normalized = ($e).toKebabCase
    for i in (0..<normalized.len):
      let substr = normalized[0 .. i]
      result[substr] = result.mgetOrPut(substr, @[]) & e


proc findMatch*[T](lookup: Table[string, seq[T]], pattern: string): MatchResult[T] =
  let match: seq[T] = lookup.getOrDefault(pattern, @[])

  return case match.len:
    of 0: MatchResult[T](kind: None)
    of 1: MatchResult[T](kind: Single, value: match[0])
    else: MatchResult[T](kind: Multi, values: match)


when isMainModule:
  type
    NumberEnum = enum
      One, Two, Three, Four, Five, Six, Seven, Eight, Nine, Ten, Eleven, Twelve,
      Thireen, Fourteen, Fifteen, Sixteen, Seventeen, Eighteen, Nineteen, Twenty

  var numberLookup = prefixTable(NumberEnum)

  echo numberLookup.findMatch("one").value == One
  echo numberLookup.findMatch("o").value == One
  echo numberLookup.findMatch("t").values ==
    @[Two, Three, Ten, Twelve, Thireen, Twenty]
  echo numberLookup.findMatch("tw").values == @[Two, Twelve, Twenty]
  echo numberLookup.findMatch("two").value == Two

