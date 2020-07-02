#[
  desc: Maillog parser for postfix log
  email: amru.rosyada@gmail.com
  git: https://github.com/zendbit
  site: skala.dev
  license: BSD
]#

import
  streams,
  os,
  nre,
  strformat,
  strutils,
  times,
  json

import
  settings,
  pg

const maillogTbl = "maillog"

if not isNil(dbConn()):
  dbConn().exec(
    sql &"""CREATE TABLE IF NOT EXISTS {maillogTbl} (
      id text NOT NULL,
      data jsonb NOT NULL,
      PRIMARY KEY (id)
    )""")

# postfix mail log parser
# type of LogParser object
type
  LogParser* = ref object
    logFile: string

proc newLogParser*(): LogParser =
  return LogParser(logFile: jsonSettings{"maillog_path"}.getStr())

proc logById*(self:LogParser, id: string): JsonNode =
  if not isNil(dbConn()):
    let row = dbConn().getRow(
      sql &"""SELECT data FROM {maillogTbl} WHERE id = ?""", id)
    if row[0] != "":
      result = parseJson(row[0])

proc logByMailId*(self:LogParser, id: string): JsonNode =
  if not isNil(dbConn()):
    let row = dbConn().getRow(
      sql &"""SELECT data FROM {maillogTbl} WHERE data->>'mail_id' = ?""", id)
    if row[0] != "":
      result = parseJson(row[0])

proc addLog*(self:LogParser, log: JsonNode) =
  let rowId = log{"row_id"}.getStr()
  let mailId = log{"mail_id"}.getStr()
  if mailId != "" and rowId != "" and isNil(self.logByMailId(mailId)) and not isNil(dbConn()):
    log["created_datetime"] = % $utc(now())
    dbConn().exec(
      sql &"""INSERT INTO {maillogTbl} (id, data) VALUES (?, ?)""",
      rowId, $log)

proc updateLog*(self:LogParser, log: JsonNode) =
  let rowId = log{"row_id"}.getStr()
  let mailId = log{"mail_id"}.getStr()
  if mailId != "" and rowId != "" and not isNil(self.logByMailId(mailId)) and not isNil(dbConn()):
    dbConn().exec(
      sql &"""UPDATE {maillogTbl} SET data = ? WHERE id = ?""",
      $log, rowId)

proc collect*(self: LogParser) =
  let logStrm = newFileStream(self.logFile, FileMode.fmRead)
  var line = ""
  if not isNil(logStrm):
    while logStrm.readLine(line):
      #echo line
      #if line.contains("9742A5F880B"):
      #  echo line
      # capture the token (datetime) (server) (process): (mail id): (info)
      # parsing this forms
      # Jun 16 11:00:29 mx postfix/smtpd[43265]: C903F5F8774: XXXX
      let capture = line.match(re"([\w]+ [\d]+ [\d]+:[\d]+:[\d]+) ([\(\)\w\d/\[\]=\-\\_@\.<>\+]+) ([\(\)\w\d/\[\]=\-\\_@\.<>\+]+): ([\(\)\w\d/\[\]=\-\\_@\.<>\+]+): ([\w\W]+)*$")
      if capture.isSome:
        let logTime = capture.get.captures[0]
        let server = capture.get.captures[1]
        let process = capture.get.captures[2].split("[")[0]
        let mailId = capture.get.captures[3]
        let processInfo = capture.get.captures[4]

        if mailId.match(re"([A-Z0-9]+)*$").isSome:
          if mailId != "NOQUEUE":
            self.addLog(%*{
              "row_id": createUId(),
              "mail_id": mailId,
              "mail_logs": []})

            let mailLogs = self.logByMailId(mailId)
            if not isNil(mailLogs):
              var mailLogList = mailLogs{"mail_logs"}
              if isNil(mailLogList):
                mailLogList = %*[]

              var exists = false
              for mlog in mailLogList:
                if mlog{"datetime"}.getStr() == logTime and mlog{"server"}.getStr() == server and
                  mlog{"process"}.getStr() == process and mlog{"process_info"}.getStr() == processInfo:
                    exists = true
                    break

              if not exists:
                mailLogList.add(%*{
                  "datetime": logTime,
                  "server": server,
                  "process": process,
                  "process_info": processInfo
                })

                self.updateLog(mailLogs)

proc mailLogs*(
  self: LogParser,
  search: string = "",
  limit: int = 20,
  offset: int = 0): JsonNode =
  if not isNil(dbConn()):
    result = %[]
    var where = ""
    var fromTbl = maillogTbl
    if search != "":
      fromTbl = &"""{maillogTbl} mlog"""
      where = &"""WHERE data->>'row_id' ILIKE '%{search}%' OR
        data->>'mail_id' ILIKE '%{search}%' OR
        (select count(pinfo.key) from jsonb_array_elements(data->'mail_logs') pinfo_arr, jsonb_each(pinfo_arr) pinfo where pinfo.value::TEXT ilike '%{search}%') > 0"""
    let rows = dbConn().getAllRows(
      sql &"""SELECT data FROM {fromTbl} {where} limit ? offset ?""", limit, offset)
    for row in rows:
      result.add(parseJson(row[0]))

proc logSummary*(self: LogParser, mailLogs: JsonNode): JsonNode =
  result = %[]
  for log in mailLogs:
    echo log.pretty()
  #[let logStrm = newFileStream(self.logFile, FileMode.fmRead)
  var line = ""
  if not isNil(logStrm):
    while logStrm.readLine(line):
      #echo line
      #if line.contains("9742A5F880B"):
      #  echo line
      # capture the token (datetime) (server) (process): (mail id): (info)
      # parsing this forms
      # Jun 16 11:00:29 mx postfix/smtpd[43265]: C903F5F8774: XXXX
      let capture = line.match(re"([\w]+ [\d]+ [\d]+:[\d]+:[\d]+) ([\(\)\w\d/\[\]=\-\\_@\.<>\+]+) ([\(\)\w\d/\[\]=\-\\_@\.<>\+]+): ([\(\)\w\d/\[\]=\-\\_@\.<>\+]+): ([\w\W]+)*$")
      if capture.isSome:
        let logTime = capture.get.captures[0]
        let server = capture.get.captures[1]
        let process = capture.get.captures[2].split("[")[0]
        let mailId = capture.get.captures[3]
        let processInfo = capture.get.captures[4]

        if mailId.match(re"([A-Z0-9]+)*$").isSome:
          if mailId != "NOQUEUE":
            #self.addLog(%*{
            #  "rowId": createUId(),
            #  "mailId": mailId,
            #  #"summary": {},
            #  "mailTracks": []})
            let mailLog = self.logByMailId(mailId)
            if not isNil(mailLog):
              mailLog["server"] = %server
              if process.contains("/smtpd"):
                let smtpd = processInfo.match(re"([\w]+)=([\w\W]+)*$")
                if smtpd.isSome:
                  let smtpdProps = processInfo.split(", ")
                  for smtpdProp in smtpdProps:
                    let indexDelimiter = smtpdProp.find("=")
                    let k = smtpdProp.substr(0, indexDelimiter - 1)
                    let v = smtpdProp.substr(indexDelimiter + 1, high(smtpdProp))
                    mailLog[k] = %v
              elif process.contains("/smtp") or process.contains("/error"):
                var smtpLog = mailLog{"to"}
                if isNil(smtpLog):
                  smtpLog = %*{}
                var to = ""
                let smtpProps = processInfo.split(", ")
                for smtpProp in smtpProps:
                  let indexDelimiter = smtpProp.find("=")
                  let k = smtpProp.substr(0, indexDelimiter - 1)
                  let v = smtpProp.substr(indexDelimiter + 1, high(smtpProp))
                  if k == "to":
                    if isNil(smtpLog{v}):
                      to = v
                      smtpLog[to] = %*{}
                    smtpLog[to]["dateTime"] = %logTime
                  else:
                    smtpLog[to][k] = %v
                mailLog["to"] = smtpLog
              elif process.contains("/qmgr") or process.contains("/cleanup"):
                if processInfo == "removed":
                  mailLog["removed"] = %true
                else:
                  let qmgrProps = processInfo.split(", ")
                  for qmgrProp in qmgrProps:
                    let indexDelimiter = qmgrProp.find("=")
                    let k = qmgrProp.substr(0, indexDelimiter - 1)
                    let v = qmgrProp.substr(indexDelimiter + 1, high(qmgrProp))
                    mailLog[k] = %v
              elif process.contains("/bounce"):
                var bounceLog = mailLog{"bounce"}
                if isNil(bounceLog):
                  bounceLog = %* @[]
                bounceLog.add(%*{
                  "dateTime": logTime, "info": processInfo})
              else:
                echo line

    logStrm.close()]#
