#[
  ZendFlow web framework for nim language
  This framework if free to use and to modify
  License: BSD
  Author: Amru Rosyada
  Email: amru.rosyada@gmail.com
  Git: https://github.com/zendbit
]#

import
  zfcore/zendFlow,
  asyncdispatch,
  src/pages/setup/setupPage

zf:
  afterRoute:
    let zfSetings = zfJsonSettings()

    # add filtering for security cors
    ctx.response.headers["Access-Control-Allow-Origin"] = "*"
    ctx.response.headers["Access-Control-Request-Method"] = "GET"

    let (ip, _) = ctx.client.getPeerAddr()
    let allowOrigin = zfSetings{"allowOrigin"}
    if allowOrigin.contains(ip):
      ctx.response.headers["Access-Control-Allow-Origin"] = ip
      ctx.response.headers["Access-Control-Request-Method"] = join(allowOrigin{ip}.to(seq[string]), ",")

    # check if the setup is completed
    #if not zfSetings{"setupCompleted"}.getBool() and
    #  not route.path.contains("#setup"):
    #  respRedirect("index.html#setup?hello=test")
    #  return true
  routes:
    staticDir "/"
    get "/liveview":
      # ctx instance of HttpCtx exposed here :-)
      let ws = ctx.webSocket
      if not isNil(ws):
        case ws.state:
        of WSState.HandShake:
          discard
          # this state will evaluate
          # right before handshake process
          # in here we can add the additionals response headers
          # normaly we can skip this step
          # about the handshake:
          # handshake is using http headers
          # this process is only happen 1 time
          # after handshake success then the protocol will be switch to the websocket
          # you can check the handshake header request in
          # -> ws.handShakeReqHeaders this is the HtttpHeaders type
          # and you also can add the additional headers information in the response handshake
          # by adding the:
          # -> ws.handShakeResHeaders
        of WSState.Open:
          discard
          # in this state all swaping process will accur
          # like send or received message
          case ws.statusCode:
          of WSStatusCode.Ok:
            case ws.inFrame.opCode:
            of WSOpCode.TextFrame.uint8:
              #echo &"Fin {ws.inFrame.fin}"
              #echo &"Rsv1 {ws.inFrame.rsv1}"
              #echo &"Rsv2 {ws.inFrame.rsv2}"
              #echo &"Rsv3 {ws.inFrame.rsv3}"
              #echo &"OpCode {ws.inFrame.opCode}"
              #echo &"Mask {ws.inFrame.mask}"
              #echo &"Mask Key {ws.inFrame.maskKey}"
              #echo &"PayloadData {ws.inFrame.payloadData}"
              #echo &"PayloadLen {ws.inFrame.payloadLen}"
              # how to show decoded data
              # we can use the encodeDecode
              #echo ""
              #echo "Received data (decoded):"
              #echo ws.inFrame.encodeDecode()
              # let send the data to the client
              # set fin to 1 if this is independent message
              # 1 meaning for read and finish
              # if you want to use continues frame
              # set it to 0
              # for more information about web socket frame and protocol
              # refer to the web socket documentation ro the RFC document
              #
              # WSOpCodeEnum:
              # WSOpCode* = enum
              #    ContinuationFrame = 0x0
              #    TextFrame = 0x1
              #    BinaryFrame = 0x2
              #    ConnectionClose = 0x8
              let inframe = ws.inFrame.encodeDecode()
              try:
                let inJson = parseJson(inframe)
                case inJson{"action"}.getStr()
                of "visitPage":
                  let url = parseUri3(inJson{"target"}.getStr())
                  case url.getPathSegment(0):
                  of "setup":
                    await setupPage.visitPage(url, ws)
                  else:
                    discard
                of "updateState":
                  let url = parseUri3(inJson{"params"}{"url"}.getStr())
                  case url.getPathSegment(0):
                  of "setup":
                    await setupPage.updateState(url, inJson{"params"}, ws)
                else:
                  discard
              except Exception:
                discard

              #ws.outFrame = newWSFrame(
              #  1,
              #  WSOpCode.TextFrame.uint8,
              #  $ %*{"action": "update_ui", "target": "content", "ui": "<h1>Hello</h1><script>alert()</script>"})
              #await ws.send()
            of WSOpCode.BinaryFrame.uint8:
              discard
            of WSOpCode.ContinuationFrame.uint8:
              # the frame continues from previous frame
              discard
            of WSOpCode.ConnectionClose.uint8:
              discard
            else:
                discard
          else:
              discard
        of WSState.Close:
          discard
          # this state will execute if the connection close
    get "/setup":
      await setupPage.index(ctx)

serve()
