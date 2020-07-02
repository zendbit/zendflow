import
  ../../radmngSettings,
  ../../plugins/liveview,
  ../../plugins/dbs,
  ../../plugins/csrf,
  ../../radconf,
  ../../syscall,
  db_postgres,
  db_mysql,
  db_sqlite

proc index*(ctx: HttpCtx): Future[void] {.async.} =
  await newLV(
    ctx,
    "master.setup",
    (await loadRadmngSettings()){"setupSection"}).updateUI()

proc updateState*(url: Uri3, params: JsonNode, ws: WebSocket): Future[void] {.async.} =
  let lv = newLV(
      ws,
      params = %*{
        "url": $url,
        "data": {"dbUser": {}, "admUser": {}},
        "isSuccess": false})

  case url.getQuery("section")
  of "done":
    let dbUser = params{"dbUser"}
    let admUser = params{"admUser"}
    let dbType = params{"dbUser"}{"dbType"}.getStr().strip()
    var dbPort = params{"dbUser"}{"dbPort"}.getStr().strip()
    let dbUserData = %*{"dbType": dbType}
    let admUserData = %*{}

    var fv = newFluentValidation()
    if dbType != "sqlite":
      if dbPort == "":
        if dbType == "postgresql":
          dbPort = "5432"
        elif dbType == "mariadb":
          dbPort = "3306"

      let dbUsername = dbUserData{"dbUsername"}.getStr().strip()
      let dbPassword = dbUserData{"dbPassword"}.getStr().strip()
      let dbDatabase = dbUserData{"dbDatabase"}.getStr().strip()
      let dbHost = dbUserData{"dbHost"}.getStr().strip()
      let dbPortInt = parseInt(dbPort)

      discard fv.add(newFieldData("dbUsername", dbUsername)
          .must("Username required.")
          .reMatch("([a-zA-Z0-9_\\-\\.]+)$", "Only contains a-z A-Z 0-9 _ - and . .")
          .maxLen(255, "Max len is 255"))
        .add(newFieldData("dbPassword", dbPassword)
          .must("Password required.")
          .maxLen(255, "Max len is 255."))
        .add(newFieldData("dbDatabase", dbDatabase)
          .must("Database required.")
          .reMatch("([a-zA-Z0-9_\\-\\.]+)$", "Database only contains a-z A-Z 0-9 _ - and . .")
          .maxLen(255, "Max len is 255"))
        .add(newFieldData("dbPort", dbPort)
          .num("Port must number.")
          .maxNum(65535, "Max value 65535.")
          .maxLen(5, "Max value 65535."))
        .add(newFieldData("dbHost", dbHost)
          .must("Host required.")
          .reMatch("([a-zA-Z0-9_\\-\\.]+)$", "Only contains a-z A-Z 0-9 _ - and . ."))
      dbUserData["isValid"] = %fv.isValid
      dbUserData["notValids"] = %fv.notValids

      # check the db connection if all field valid
      if dbUserData["isValid"].getBool():
        if dbType == "postgresql" and
          newDbs[db_postgres.DbConn](
            dbDatabase,
            dbUsername,
            dbPassword,
            dbHost,
            dbPortInt).tryPgSqlCheck():
          echo "Connected.."
        elif dbType == "mysql" and
          newDbs[db_mysql.DbConn](
            dbDatabase,
            dbUsername,
            dbPassword,
            dbHost,
            dbPortInt).tryMySqlCheck():
          echo "Connected.."
        elif newDbs[db_sqlite.DbConn]("src/data/radmng.db", "", "", "", 0).trySqliteCheck():
          echo "Connected.."
    else:
      dbUserData["isValid"] = %true

    fv.clear()
    fv.add(newFieldData("admUsername", admUser{"admUsername"}.getStr().strip())
        .must("Email required.")
        .reMatch("([a-zA-Z0-9_\\-\\.]+@[a-zA-Z0-9_\\-\\.]+\\.[a-zA-Z0-9_\\-\\.]+)$", "Email format not valid.")
        .maxLen(255, "Max username len is 255"))
      .add(newFieldData("admPassword", admUser{"admPassword"}.getStr().strip())
        .must("Password required.")
        .minLen(6, "Pasword must have at least 6 char.")
        .maxLen(255, "Max password len is 255."))

    let validateConfirmPass = newFieldData("admPassword2", admUser{"admPassword2"}.getStr().strip())
    if admUser{"admPassword"}.getStr().strip() != admUser{"admPassword2"}.getStr().strip():
      fv.add(validateConfirmPass.customErr("Confirmation password doesn't match."))
    else:
      fv.add(validateConfirmPass.customOk())

    admUserData["isValid"] = %fv.isValid
    admUserData["notValids"] = %fv.notValids

    lv.params["isSuccess"] = %(admUserData{"isValid"}.getBool() and dbUserData{"isValid"}.getBool())
    lv.params["data"]["dbUser"] = dbUserData
    lv.params["data"]["admUser"] = admUserData

    if not lv.params["isSuccess"].getBool():
      await lv.updateState()
    else:
      echo ""

proc visitPage*(url: Uri3, ws: WebSocket): Future[void] {.async.} =
  let lv = newLV(
      ws,
      target = "updateContent",
      uiParams = %*{"isLoading": true},
      params = %*{"url": $url})

  case url.getQuery("section")
  of "validateRadius":
    lv.ui = "setup.validateRadius"
    await lv.updateUI()

    let radConf = await findRadConf()
    lv.uiParams["radConf"] = %radConf
    lv.uiParams["isLoading"] = %false
    lv.uiParams["isRadConfExists"] = %(radConf.len != 0)
    if lv.uiParams["isRadConfExists"].getBool():
      let radmngSettings = await loadRadmngSettings()
      if not isNil(radmngSettings):
        radmngSettings["radConfPath"] = %radConf[0]
        await updateRadmngSettings(radmngSettings)
        discard await loadRadConf()
        var radenv = newJArray()
        for key, val in radEnv().pairs:
          radenv.add(%*{"name": key, "path": val})

        lv.uiParams["radEnv"] = radenv

    await lv.updateUI()

  of "databaseSetup":
    lv.ui = "setup.database"
    await lv.updateUI()

    lv.uiParams["isLoading"] = %false
    await lv.updateUI()

  else:
    lv.ui = "setup.intro"
    await lv.updateUI()
