import
  httpclient,
  asyncdispatch,
  uri3,
  strformat,
  json,
  strutils

type
  FoxDriver* = ref object
    httpClient: AsyncHttpClient
    host: string
    port: uint
    remoteUrl: Uri3
    firefoxExe*: string
    sessionId*: string

  FoxRespMsg* = object
    status*: string
    success*: bool
    message*: JsonNode
    error*: JsonNode

  LocationStrategy* = enum
    CssSelector,
    LinkTextSelector,
    PartialLinkSelector,
    TagName,
    XPathSelector

  KeyActionType* = enum
    KeyUp,
    KeyDown,
    KeyPause

  PointerActionType* = enum
    PointerPause,
    PointerUp,
    PointerDown,
    PointerMove,
    PointerCancel

proc newFoxRespMsg*(
  status: string = $Http404,
  success: bool = false,
  message: JsonNode = JsonNode(),
  error: JsonNode = JsonNode()): FoxRespMsg =
  return FoxRespMsg(status: status, success: success, message: message, error: error)

proc newFoxDriver*(
  host: string = "http://10.0.0.2",
  port: uint = 4445,
  firefoxExe: string = "firefox"): FoxDriver =
  result = FoxDriver(host: host, port: port, firefoxExe: firefoxExe)
  result.remoteUrl = parseUri3(&"{host}:{port}")
  result.httpClient = newAsyncHttpClient()

proc `$`*(strategy: LocationStrategy): string =
  case strategy
  of CssSelector:
    result = "css selector"
  of LinkTextSelector:
    result = "link text"
  of PartialLinkSelector:
    result = "partial link text"
  of TagName:
    result = "tag name"
  of XPathSelector:
    result = "xpath"

proc `$`*(key: KeyActionType): string =
  case key
  of KeyUp:
    result = "keyUp"
  of KeyDown:
    result = "keyDown"
  of KeyPause:
    result = "pause"

proc `$`*(pt: PointerActionType): string =
  case pt
  of PointerPause:
    result = "pause"
  of PointerCancel:
    result = "pointerCancel"
  of PointerDown:
    result = "pointerDown"
  of PointerMove:
    result = "pointerMove"
  of PointerUp:
    result = "pointerUp"

proc parseResp(self: FoxDriver, res: AsyncResponse): Future[FoxRespMsg] {.async.} =
  result = newFoxRespMsg()
  try:
    let statusInt = parseInt(res.status.split(" ")[0])
    result.status = res.status
    result.success =  statusInt >= 200 and statusInt < 300
    let body = parseJson(await res.body)
    let error = body{"value"}{"error"}.getStr()
    let message = body{"value"}{"message"}.getStr()
    let ready = body{"value"}{"ready"}
    if not result.success:
      result.error = %error
      result.message = %message
    else:
      if not isNil(ready):
        result.message = %*{"ready": ready.getBool()}
      else:
        result.message = body{"value"}
  except Exception as ex:
    result.success = false
    result.status = $Http500
    result.error = %ex.msg

proc status*(self: FoxDriver): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.get($(self.remoteUrl/"status"))
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc timeouts*(self: FoxDriver, sessionId: string): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.get($(self.remoteUrl/"session"/sessionId/"timeouts"))
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc setTimeouts*(
  self: FoxDriver,
  sessionId: string,
  script: int = -1,
  pageLoad: int = -1,
  implicit: int = -1): Future[FoxRespMsg] {.async.} =
  try:
    let params = %*{}
    if script > -1: params["script"] = %script
    if pageLoad > -1: params["pageLoad"] = %pageLoad
    if implicit > -1: params["implicit"] = %implicit
    let res = await self.httpClient.post(
      $(self.remoteUrl/"session"/sessionId/"timeouts"),
      $params)
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc back*(self: FoxDriver): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.post($(self.remoteUrl/"session"/self.sessionId/"back"), "{}")
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc forward*(self: FoxDriver): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.post($(self.remoteUrl/"session"/self.sessionId/"forward"), "{}")
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc refresh*(self: FoxDriver): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.post($(self.remoteUrl/"session"/self.sessionId/"refresh"), "{}")
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc setUrl*(self: FoxDriver, url: string): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.post(
      $(self.remoteUrl/"session"/self.sessionId/"url"),
      $ %*{"url": url})
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc url*(self: FoxDriver): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.get($(self.remoteUrl/"session"/self.sessionId/"url"))
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc title*(self: FoxDriver): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.get($(self.remoteUrl/"session"/self.sessionId/"title"))
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc window*(self: FoxDriver): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.get($(self.remoteUrl/"session"/self.sessionId/"window"))
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc switchToWindow*(self: FoxDriver, handle: string): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.post(
      $(self.remoteUrl/"session"/self.sessionId/"window"),
      $ %*{"handle": handle})
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc closeWindow*(self: FoxDriver): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.delete($(self.remoteUrl/"session"/self.sessionId/"window"))
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc windowHandles*(self: FoxDriver): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.get($(self.remoteUrl/"session"/self.sessionId/"window/handles"))
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc windowRect*(self: FoxDriver): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.get($(self.remoteUrl/"session"/self.sessionId/"window/rect"))
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc setWindowRect*(self: FoxDriver, x, y, width, height: int): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.post(
      $(self.remoteUrl/"session"/self.sessionId/"window/rect"),
      $ %*{"x": x, "y": y, "width": width, "height": height})
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc maximizeWindow*(self: FoxDriver): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.post(
      $(self.remoteUrl/"session"/self.sessionId/"window/maximize"), "{}")
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc minimizeWindow*(self: FoxDriver): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.post(
      $(self.remoteUrl/"session"/self.sessionId/"window/minimize"), "{}")
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc fullscreenWindow*(self: FoxDriver): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.post(
      $(self.remoteUrl/"session"/self.sessionId/"window/fullscreen"), "{}")
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc switchToParentFrame*(self: FoxDriver): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.post(
      $(self.remoteUrl/"session"/self.sessionId/"frame/parent"), "{}")
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc switchToFrame*(self: FoxDriver, frameIdx: int): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.post(
      $(self.remoteUrl/"session"/self.sessionId/"frame"), $ %*{"id": frameIdx})
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc closeSession*(self: FoxDriver): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.delete($(self.remoteUrl/"session"/self.sessionId))
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc createSession*(self: FoxDriver, options: JsonNode = JsonNode()): Future[FoxRespMsg] {.async.} =
  result = await self.status()
  if result.success and result.message{"ready"}.getBool():
    try:
      # set default parameter for session if session capabilities is nil
      let sessionOptions = %*{}
      if isNil(options{"capabilities"}):
        sessionOptions["capabilities"] = %*{
          "alwaysMatch": {
              "moz:firefoxOptions": {
                "binary": self.firefoxExe
                #"args": ["-headless"]
              }
            }
        }

      let res = await self.httpClient.post(
        $(self.remoteUrl/"session"),
        $sessionOptions)

      result = await self.parseResp(res)
      self.sessionId = result.message{"sessionId"}.getStr()
    except Exception as ex:
      result = newFoxRespMsg($Http500, error = %ex.msg)

proc findElement*(
  self: FoxDriver,
  value: string,
  strategy: LocationStrategy = CssSelector): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.post(
      $(self.remoteUrl/"session"/self.sessionId/"element"),
      $ %*{"using": $strategy, "value": value})
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc findElements*(
  self: FoxDriver,
  value: string,
  strategy: LocationStrategy = CssSelector): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.post(
      $(self.remoteUrl/"session"/self.sessionId/"elements"),
      $ %*{"using": $strategy, "value": value})
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc findChild*(
  self: FoxDriver,
  elementId: string,
  value: string,
  strategy: LocationStrategy = CssSelector): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.post(
      $(self.remoteUrl/"session"/self.sessionId/"element"/elementId/"element"),
      $ %*{"using": $strategy, "value": value})
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc findChilds*(
  self: FoxDriver,
  elementId: string,
  value: string,
  strategy: LocationStrategy = CssSelector): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.post(
      $(self.remoteUrl/"session"/self.sessionId/"element"/elementId/"elements"),
      $ %*{"using": $strategy, "value": value})
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc activeElement*(self: FoxDriver): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.get($(self.remoteUrl/"session"/self.sessionId/"element/active"))
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc isElementSelected*(self: FoxDriver, elementId: string): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.get($(self.remoteUrl/"session"/self.sessionId/"element"/elementId/"selected"))
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc elementAttribute*(self: FoxDriver, elementId: string, attrName: string): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.get(
      $(self.remoteUrl/"session"/self.sessionId/"element"/elementId/"attribute"/attrName))
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc elementProperty*(self: FoxDriver, elementId: string, propName: string): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.get(
      $(self.remoteUrl/"session"/self.sessionId/"element"/elementId/"property"/propName))
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc elementCss*(self: FoxDriver, elementId: string, propName: string): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.get(
      $(self.remoteUrl/"session"/self.sessionId/"element"/elementId/"css"/propName))
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc elementName*(self: FoxDriver, elementId: string): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.get(
      $(self.remoteUrl/"session"/self.sessionId/"element"/elementId/"name"))
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc elementRect*(self: FoxDriver, elementId: string): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.get(
      $(self.remoteUrl/"session"/self.sessionId/"element"/elementId/"rect"))
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc isElementEnabled*(self: FoxDriver, elementId: string): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.get(
      $(self.remoteUrl/"session"/self.sessionId/"element"/elementId/"enabled"))
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc elementClick*(self: FoxDriver, elementId: string): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.post(
      $(self.remoteUrl/"session"/self.sessionId/"element"/elementId/"click"), "{}")
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc elementClear*(self: FoxDriver, elementId: string): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.post(
      $(self.remoteUrl/"session"/self.sessionId/"element"/elementId/"clear"), "{}")
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc pageSource*(self: FoxDriver): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.get($(self.remoteUrl/"session"/self.sessionId/"source"))
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc sendKey*(self: FoxDriver, elementId: string, text: string): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.post(
      $(self.remoteUrl/"session"/self.sessionId/"element"/elementId/"value"),
      $ %*{"text": text})
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc executeScript*(self: FoxDriver, script: string, arguments: seq[JsonNode]): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.post(
      $(self.remoteUrl/"session"/self.sessionId/"execute/sync"),
      $ %*{
        "script": script,
        "args": arguments
      })
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc executeScriptAsync*(self: FoxDriver, script: string, arguments: seq[JsonNode]): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.post(
      $(self.remoteUrl/"session"/self.sessionId/"execute/async"),
      $ %*{
        "script": script,
        "args": arguments
      })
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc elementIds*(self: FoxDriver, foxResp: FoxRespMsg): seq[string] =
  if not isNil(foxResp.message):
    for _, v in foxResp.message.pairs:
      result.add(v.getStr())

proc allCookies*(self: FoxDriver): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.get($(self.remoteUrl/"session"/self.sessionId/"cookie"))
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc cookieByName*(self: FoxDriver, name: string): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.get($(self.remoteUrl/"session"/self.sessionId/"cookie"/name))
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc deleteCookieByBame*(self: FoxDriver, name: string): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.delete($(self.remoteUrl/"session"/self.sessionId/"cookie"/name))
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc deleteAllCookies*(self: FoxDriver): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.delete($(self.remoteUrl/"session"/self.sessionId/"cookie"))
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc addCookie*(
  self: FoxDriver,
  name: string,
  value: string,
  path: string = "/",
  domain: string = "",
  secure: bool = false,
  httpOnly: bool = false,
  expiry: int64 = -1): Future[FoxRespMsg] {.async.} =
  try:
    let cookie = %*{
      "cookie": {
        "name": name,
        "value": value,
        "path": path,
        "secure": secure,
        "httpOnly": httpOnly
      }
    }
    if domain != "": cookie["cookie"]["domain"] = %domain
    if expiry != -1: cookie["cookie"]["expiry"] = %expiry
    let res = await self.httpClient.post(
      $(self.remoteUrl/"session"/self.sessionId/"cookie"),
      $cookie)
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

proc sendKeyAction*(self: FoxDriver, keyType: KeyActionType, ): Future[FoxRespMsg] {.async.} =
  try:
    let res = await self.httpClient.get($(self.remoteUrl/"session"/self.sessionId/"cookie"))
    result = await self.parseResp(res)
  except Exception as ex:
    result = newFoxRespMsg($Http500, error = %ex.msg)

#3826e043-c4a4-402f-9a97-514b7e1cbe26
let foxDriver = newFoxDriver()
echo %(waitFor foxDriver.createSession())
foxDriver.sessionId = "e17acfb5-5706-4744-a31b-9ad77baf7aad"
#echo %(waitFor foxDriver.setUrl("https://google.com"))
#echo %(waitFor foxDriver.title())
#echo %(waitFor foxDriver.window())
#echo %(waitFor foxDriver.windowHandles())
#echo %(waitFor foxDriver.switchToWindow("6442450945"))
#echo %(waitFor foxDriver.closeWindow())
#echo %(waitFor foxDriver.switchToParentFrame())
#echo %(waitFor foxDriver.findElement("//iframe[@id='test']", XPathSelector))
#echo %(waitFor foxDriver.switchToFrame(0))
#echo %(waitFor foxDriver.windowRect())
#echo %(waitFor foxDriver.setWindowRect(30, 30, 600, 540))
#echo %(waitFor foxDriver.maximizeWindow())
#echo %(waitFor foxDriver.minimizeWindow())
#echo %(waitFor foxDriver.fullscreenWindow())
#echo %(waitFor foxDriver.findElement("//input[@class='gLFyf gsfi']", XPathSelector))
#echo %(waitFor foxDriver.findElements("div", CssSelector))
#echo %(waitFor foxDriver.findChilds("7b26c2b0-0d57-47e3-a27c-32f22123bf5f", "div", CssSelector))
#echo %(waitFor foxDriver.activeElement())
#echo %(waitFor foxDriver.isElementSelected("f7c7768b-1672-47b1-8f06-c57e5e285d45"))
#echo %(waitFor foxDriver.elementAttribute("f7c7768b-1672-47b1-8f06-c57e5e285d45", "type"))
#echo %(waitFor foxDriver.elementProperty("f7c7768b-1672-47b1-8f06-c57e5e285d45", "value"))
#echo %(waitFor foxDriver.elementCss("f7c7768b-1672-47b1-8f06-c57e5e285d45", "width"))
#echo %(waitFor foxDriver.elementName("f7c7768b-1672-47b1-8f06-c57e5e285d45"))
#echo %(waitFor foxDriver.elementRect("f7c7768b-1672-47b1-8f06-c57e5e285d45"))
#echo %(waitFor foxDriver.isElementEnabled("f7c7768b-1672-47b1-8f06-c57e5e285d45"))
#echo %(waitFor foxDriver.elementClick("f7c7768b-1672-47b1-8f06-c57e5e285d45"))
#echo %(waitFor foxDriver.elementClear("f7c7768b-1672-47b1-8f06-c57e5e285d45"))
#echo %(waitFor foxDriver.executeScript(
#  """
#  alert(arguments[0]);
#  """,
#  @[%"hello"]
#))
#let elmId = foxDriver.elementIds(waitFor foxDriver.findElement("//input[@class='gLFyf gsfi']", XPathSelector))
#echo %(waitFor foxDriver.sendKey(elmId[0], "wikipedia"))
#echo %(waitFor foxDriver.pageSource())
#echo %(waitFor foxDriver.allCookies())
#echo %(waitFor foxDriver.cookieByName("NID"))
#echo %(waitFor foxDriver.addCookie("test", "testvalue", "/", ".google.com", true, true, 1607658818))
#echo %(waitFor foxDriver.allCookies())
#discard waitFor foxDriver.closeSession()

#echo %(waitfor foxDriver.timeouts("3826e043-c4a4-402f-9a97-514b7e1cbe26"))
#echo %(waitfor foxDriver.setTimeouts(
#  "3826e043-c4a4-402f-9a97-514b7e1cbe26",
#  %*{
#    "script": %30000,
#    "pageLoad": %300000,
#    "implicit": %0
#  }
#))
#echo %(waitfor foxDriver.setUrl("3826e043-c4a4-402f-9a97-514b7e1cbe26", "https://facebook.com"))
#echo %(waitfor foxDriver.url("3826e043-c4a4-402f-9a97-514b7e1cbe26"))
#echo %(waitfor foxDriver.refresh("3826e043-c4a4-402f-9a97-514b7e1cbe26"))
#echo %(waitfor foxDriver.forward("3826e043-c4a4-402f-9a97-514b7e1cbe26"))
#if (waitfor foxDriver.status()){"value"}{"ready"}.getBool():
#  echo "web driver ready"
#echo waitfor newFoxDriver().createSession()
#echo waitFor newFoxDriver().deleteSession("7409917d-2df5-49bc-91ff-1c3bf6c0901a")
