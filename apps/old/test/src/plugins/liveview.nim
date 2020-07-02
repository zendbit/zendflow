import
  zfcore/zendflow,
  json,
  moustachu,
  tpl,
  asyncdispatch,
  tables

type
  LVAct*[T] = ref object
    ctx*: T
    p*: JsonNode

  LV*[T] = ref object of RootObj
    ctx*: T
    target*: string
    ui*: string
    uiParams*: JsonNode
    params*: JsonNode
    call*: Table[string, proc (): Future[void]]

proc newLV*(
  ctx: WebSocket,
  target: string = "",
  ui: string = "",
  uiParams: JsonNode = JsonNode(),
  params: JsonNode = JsonNode()): LV[WebSocket] =
  return LV[WebSocket](
    ctx: ctx,
    target: target,
    ui: ui,
    uiParams: uiParams,
    params: params)

proc newLV*(
  ctx: HttpCtx,
  ui: string = "",
  uiParams: JsonNode = JsonNode()): LV[HttpCtx] =
  return LV[HttpCtx](
    ctx: ctx,
    ui: ui,
    uiParams: uiParams)

proc act*(
  self: LVAct,
  ws: WebSocket,
  p: JsonNode = JsonNode()): Future[void] {.async.} =
  await ws.send(newWSFrame($ p))

proc act*(
  self: LVAct,
  ctx: HttpCtx,
  p: JsonNode = JsonNode()): Future[void] {.async.} =
  respHtml(Http200, p{"ui"}.getStr())

proc act*(self: LVAct): Future[void] {.async.} =
  if self.ctx is WebSocket:
    await self.act(cast[WebSocket](self.ctx), self.p)
  elif self.ctx is HttpCtx:
    await self.act(cast[HttpCtx](self.ctx), self.p)

proc updateUI*(self: LV[WebSocket]): Future[void] {.async.} =
  await LVAct[WebSocket](
    ctx: self.ctx,
    p: %*{
      "action": "updateUI",
      "target": self.target,
      "ui": render(loadTpl(self.ui), self.uiParams),
      "params": self.params}).act()

proc updateUI*(self: LV[HttpCtx]): Future[void] {.async.} =
  await LVAct[HttpCtx](
    ctx: self.ctx,
    p: %*{"ui": render(loadTpl(self.ui), self.uiParams)}).act()

proc updateState*(self: LV[WebSocket]): Future[void] {.async.} =
  await LVAct[WebSocket](
    ctx: self.ctx,
    p: %*{
      "action": "updateState",
      "params": self.params}).act()

proc visitPage*(self: LV): Future[void] {.async.} =
  await LVAct[WebSocket](
    ctx: self.ctx,
    p: %*{
      "action": "visitPage",
      "target": self.target,
      "params": self.params}).act()

export
  zendflow,
  json,
  moustachu,
  tpl,
  asyncdispatch
