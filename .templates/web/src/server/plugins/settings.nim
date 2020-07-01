import
  os,
  json

let jsonSettingsFile = joinPath(getAppDir(), "settings.json")
var jsonSettings*: JsonNode
if existsFile(jsonSettingsFile):
  try:
    echo "settings.json found."
    jsonSettings = parseFile(jsonSettingsFile)

  except Exception as ex:
    echo ex.msg

else:
  echo "settings.json not found!!."
