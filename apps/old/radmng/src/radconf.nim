import
  radmngSettings,
  asyncdispatch,
  json,
  os,
  strutils,
  streams,
  re,
  syscall

var radiusPathEnv: JsonNode

# load radius configuration
# from data/radmngSettings.json
# if not exist will return nil
proc loadRadConf*(): Future[string] {.async.} =
  let settings = await loadRadmngSettings()
  if not isNil(settings):
    let radConfPath = settings{"radConfPath"}.getStr()
    if fileExists(radConfPath):
      let radiusConf = open(radConfPath).readAll().replace("\t", "  ")
      let radConfStream = newStringStream(radiusConf)
      var line = ""
      radiusPathEnv = parseJson("{}")
      radiusPathEnv.add("radconf", %radConfPath)
      radiusPathEnv.add("radexec", % await radExecutable())
      var nestedBlock = 0
      while radConfStream.readLine(line):
        let lineStrip = line.strip()
        if not lineStrip.strip().startsWith("#") and
          lineStrip != "":
          if not lineStrip.contains("${"):
            if not lineStrip.contains("{") and
              nestedBlock == 0:
              let kv = lineStrip.split("=")
              if kv.len == 2:
                let k = kv[0].strip()
                let v = kv[1].strip()
                if k in [
                  "prefix", "exec_prefix", "sysconfdir", "localstatedir",
                  "sbindir", "logdir", "raddbdir", "radacctdir", "name",
                  "confdir", "modconfdir", "certdir", "cadir", "run_dir",
                  "db_dir", "libdir", "pidfile", "checkrad"]:
                  radiusPathEnv.add(k, %v)
            elif lineStrip == "}":
              nestedBlock -= 1
            else:
              nestedBlock += 1
          # get path and populate
          # by replace ${val} with actual value
          # then save to the radiusPathEnv
          elif lineStrip.contains("${") and
            (lineStrip.endsWith("}") or lineStrip.contains("}")) and
            nestedBlock == 0:
            var result = findAll(lineStrip, re"\${([\w\W]+)}/|\${([\w\W]+)}", 0)
            if result.len != 0:
              let kv = lineStrip.split("=")
              var v = kv[1].strip()
              for i in result:
                let varname = i.replace("/", "")
                let keyname = varname.replace("${", "").replace("}", "")
                if radiusPathEnv.hasKey(keyname):
                  v = v.replace(varname,
                    radiusPathEnv[keyname].getStr())

              radiusPathEnv.add(kv[0].strip(), %v)
      radConfStream.close()
      return radiusConf

proc radEnv*(): JsonNode =
  # check ana init the radius dir
  for key, val in radiusPathEnv.pairs:
    let name = key
    let path = val.getStr()
    if name.contains("dir") and not dirExists(path):
      createDir(path)
    elif path.contains(".log") and not fileExists(path):
      writeFile(path, "")
  return radiusPathEnv
