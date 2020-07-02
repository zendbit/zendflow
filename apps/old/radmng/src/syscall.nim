# system call tools
import
  osproc,
  asyncdispatch,
  strutils

proc findRadConf*(): Future[seq[string]] {.async.} =
  let (output, exitCode) = execCmdEx("find /etc /opt /usr -iname \"*radius*.conf\" 2>/dev/null | grep radius")
  if exitCode == 0:
    return output.strip().split("\n")

proc radExecutable*(): Future[string] {.async.} =
  var (output, exitCode) = execCmdEx("which radiusd")
  if exitCode != 0:
    (output, exitCode) = execCmdEx("which freeradius")
  if exitCode == 0:
    return output
