import
  os,
  json

let jsonSettingsFile = joinPath(getAppDir(), "settings.json")
var jsonSettings*: JsonNode
if existsFile(jsonSettingsFile):
  jsonSettings = parseFile(jsonSettingsFile)
