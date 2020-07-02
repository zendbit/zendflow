import
  zfcore/zendflow,
  os,
  strformat,
  strutils

proc templateDir(): string =
  var tplDir = zfJsonSettings(){"templateDir"}.getStr()
  if tplDir == "":
    tplDir = joinPath("src", "pages")
  return tplDir

# load template file
# templateDir/{a.b.c}.html
proc loadTpl*(tpl: string): string =
  let tpl = tpl.replace(".", $DirSep)
  let tplFile = joinPath(templateDir(), &"{tpl}.html")
  if fileExists(tplFile):
    return  open(tplFile).readAll()
