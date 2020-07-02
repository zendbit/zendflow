import
  json,
  asyncdispatch,
  os,
  zfcore/zendflow

proc settingsPath(): string =
  return zfJsonSettings(){"radmngSettings"}.getStr()

# parse data/radmngSettings.json
proc loadRadmngSettings*(): Future[JsonNode] {.async.} =
  if fileExists(settingsPath()):
    return parseFile(settingsPath())

proc updateRadmngSettings*(settings: JsonNode): Future[void] {.async.} =
  writeFile(settingsPath(), $settings.pretty())
