##
##  zfcore web framework for nim language
##  This framework if free to use and to modify
##  License: BSD
##  Author: Amru Rosyada
##  Email: amru.rosyada@gmail.com
##  Git: https://github.com/zendbit
##

## import zfcore
import zfcore/server

routes:
  # redirect to index/<user>
  # user will use World\
  get "/":
    respRedirect("/index/World")
  
  # websocket example :-)
  get "/ws":
    #
    # ctx instance of HttpCtx exposed here :-)
    # ws is shorthand of ctx.websocket
    #
    if not ws.isNil:
      case ws.state:
      of WSState.HandShake:
        echo "HandShake state"
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
        echo "Open state"
        # in this state all swaping process will accur
        # like send or received message
        case ws.statusCode:
        of WSStatusCode.Ok:
          case ws.inFrame.opCode:
          of WSOpCode.TextFrame.uint8:
            echo "Text frame received"
            echo &"Fin {ws.inFrame.fin}"
            echo &"Rsv1 {ws.inFrame.rsv1}"
            echo &"Rsv2 {ws.inFrame.rsv2}"
            echo &"Rsv3 {ws.inFrame.rsv3}"
            echo &"OpCode {ws.inFrame.opCode}"
            echo &"Mask {ws.inFrame.mask}"
            echo &"Mask Key {ws.inFrame.maskKey}"
            echo &"PayloadData {ws.inFrame.payloadData}"
            echo &"PayloadLen {ws.inFrame.payloadLen}"
            # how to show decoded data
            # we can use the encodeDecode
            echo ""
            echo "Received data (decoded):"
            echo ws.inFrame.encodeDecode()
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
            ws.outFrame = newWSFrame(
              "This is from the endpoint :-)",
              1,
              WSOpCode.TextFrame.uint8)
            await ws.send()
          of WSOpCode.BinaryFrame.uint8:
            echo "Binary frame received"
          of WSOpCode.ContinuationFrame.uint8:
            # the frame continues from previous frame
            echo "Continuation frame received"
          of WSOpCode.ConnectionClose.uint8:
            echo "Connection close frame received"
          else:
              discard
        else:
            echo &"Failed status code {ws.statusCode}"
      of WSState.Close:
        echo "Close state"
        # this state will execute if the connection close


  # this static route wil serve under
  # all static resource will serve under / uri path
  # address:port/
  # example address:port/style/*.css
  # if you custumize the static route for example zf.r.static("/public")
  # it will serve with address:port/public/
  # we can retrieve using address:port/public/style/*.css
  staticDir "/"

  # using regex for matching the request
  # the regex is regex match like in pcre standard like regex on python, perl etc
  # <ids:re[([0-9]+)_([0-9]+)]>
  # - the ids wil capture as parameter name
  # - the len[2] is for len for capturing in this case in the () bracket,
  #   will capture ([0-9]+) twice
  # - if only want to capture one we must exactly match len[n]
  #   with number of () capturing bracket
  # - capture regex will return list of match and can be access using ctx.ctxReParams
  # - if we want to capture segment parameter we can use <param_to_capture>
  #   in this case we use <name>
  # - <name> will capture segment value in there as name,
  #   we can access param value and query string in HttpCtx.ctxParams["name"] or other param name
  get "/req/<ids:re[([0-9]+)_([0-9]+)]>/<name>":
    echo "Welcome req"
    # capture regex result from the url
    echo reParams["ids"]
    # capture <name> value parameter from the url
    echo params["name"]
    # we can also set custom header for the response
    # using ctx.responseHeaders.add("header kye", "header value")
    response.headers.add("Content-Type", "text/plain")
    Http200.respHtml("Hello World get request")

  #get "/req/<id>/<name>":
  #  echo ctx.ctxParams["name"]
  #  echo ctx.ctxParams["id"]
  #  resp(Http200, "Ok")

  get "/req/<id>":
    # capture the <id> from the path
    echo params["id"]
    Http200.resp("Hello World patch request")

  patch "/req/<id>":
    # capture the <id> from the path
    echo params["id"]
    Http200.resp("Hello World patch request")

  delete "/req/<id>":
    # capture the <id> from the path
    echo params["id"]
    Http200.resp("Hello World delete request")

  put "/req/<id>":
    # capture the <id> from the path
    echo params["id"]
    Http200.resp("Hello World put request")

  head "/req/<id>":
    # capture the <id> from the path
    echo params["id"]
    Http200.resp("Hello World head request")

  # before Route here
  # you can filter the context request here before route happen
  # use full if we want to filtering the domain access or auth or other things that fun :-)
  # make sure if call response directly from middleware
  # require call return true for breaking the pipeline:
  #   resp(Http404, "page not found"))
  #   return true
  before:
    # ctx instance of HttpCtx exposed here :-)
    #
    echo "before route"

  # after Route here
  # you can filter the context request here after route happen
  # use full if we want to filtering the domain access or auth or other things that fun :-)
  # make sure if call response directly from middleware
  # require call return true for breaking the pipeline:
  #   resp(Http404, "page not found"))
  #   return true
  after:
    # ctx instance of HttpCtx exposed here :-)
    # route instance of Route exposed here :-)
    #
    echo "Hello World"

