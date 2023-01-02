proc log*(msg: string): void =
  stderr.writeLine(msg)
