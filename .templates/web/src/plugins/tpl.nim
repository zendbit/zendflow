import
  zfcore/zendflow,
  os,
  strformat,
  strutils

proc templateDir(): string =
  var tplDir = zfJsonSettings(){"templateDir"}.getStr()
  if tplDir == "":
    tplDir = "html"
  return tplDir

# load template file
# templateDir/{a.b.c}.html
proc loadTpl*(tpl: string): string =
  let t = tpl.replace(".", $DirSep)
  let tplFile = joinPath(templateDir(), &"{t}.html")
  if fileExists(tplFile):
    return  open(tplFile).readAll()
