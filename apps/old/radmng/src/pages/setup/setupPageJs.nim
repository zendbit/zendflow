import
  ../../tojs/init,
  ../../tojs/jObj,
  ../../tojs/liveview,
  strutils,
  strformat,
  json,
  uri3,
  dom

proc updateState*(url: Uri3, params: JsonNode) =
  case url.getQuery("section")
  of "done":
    if not params{"isSuccess"}.getBool():
      let dbUser = params{"data"}{"dbUser"}
      let admUser = params{"data"}{"admUser"}
      # clear all error codes
      jq(&"span[class*='error']").remove()

      if not dbUser{"isValid"}.getBool():
        for key, val in dbUser{"notValids"}.pairs():
          jq(&"input[name='{key}']")
            .parent()
            .append(&"""<span style="display:block" class="error invalid-feedback">{val["msg"].getStr()}</span>""")

      if not admUser{"isValid"}.getBool():
        for key, val in admUser{"notValids"}.pairs():
          jq(&"input[name='{key}']")
            .parent()
            .append(&"""<span style="display:block" class="error invalid-feedback">{val["msg"].getStr()}</span>""")

proc updateUI*(url: Uri3) =
  case url.getQuery("section")
  of "validateRadius":
    # database setup button event on validate radius section
    let databaseSetup = jq("#databaseSetup")
    if not isNil(databaseSetup) and not isUndefined(databaseSetup[0]):
      databaseSetup.click(proc (evt: JsObject) =
        evt.preventDefault()
        lvVisitPage($evt.target.href)
      )

  of "databaseSetup":
    # database selection event on database section
    let selectDb = jq("#selectDb")
    var selectedDb = "sqlite"
    if not isNil(selectDb) and not isUndefined(selectDb[0]):
      # database user info, only show details when not sqlite
      let dbUserInfo = jq("#dbUserInfo")
      if not isNil(dbUserInfo):
        dbUserInfo.hide()

      selectDb.change(proc (evt: JsObject) =
        selectedDb = toLowerAscii($evt.target.value.to(cstring))
        if selectedDb != "sqlite":
          dbUserInfo.show()
        else:
          dbUserInfo.hide()
      )

    # done setup button event
    let doneSetup = jq("#doneSetup")
    if not isNil(doneSetup) and not isUndefined(doneSetup[0]):
      doneSetup.click(proc (evt: JsObject) =
        evt.preventDefault()
        evt.target.text = "Sending...".cstring
        let dbUserInfoForm = %*{"dbUser": {"dbType": selectedDb}, "admUser": {}, "url": $evt.target.href}
        for input in jq("input[name*='db']").items:
          let val = input.value
          let name = input.name
          if not isUndefined(val) and not isUndefined(name):
            dbUserInfoForm["dbUser"][$name] = % $val

        for input in jq("input[name*='adm']").items:
          let val = input.value
          let name = input.name
          if not isUndefined(val) and not isUndefined(name):
            dbUserInfoForm["admUser"][$name] = % $val

        lvUpdateState(dbUserInfoForm)
        evt.target.text = "Done".cstring
      )

  else:
    # start setup button event on intro section
    let startSetup = jq("#startSetup")
    if not isNil(startSetup) and not isUndefined(startSetup[0]):
      startSetup.click(proc (evt: JsObject) =
        evt.preventDefault()
        lvVisitPage($evt.target.href)
      )
