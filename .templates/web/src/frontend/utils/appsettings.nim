import ffi
import localStorage

##
##  store config to the localstorage
##

const appSettings = "appSettings"

proc initSettings() =
  if getItem(appSettings).isNil:
    setItem(appSettings, "{}")

proc loadSettings*(): JsAssoc[cstring, cstring] =
  initSettings()
  result = fromJson(getItem(appSettings))

proc saveSettings*(settings: JsAssoc[cstring, cstring]) =
  initSettings()
  setItem(appSettings, toJson(settings))

proc clearSettings*() =
  removeItem(appSettings)
  setItem(appSettings, "{}")
