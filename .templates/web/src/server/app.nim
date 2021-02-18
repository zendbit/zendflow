#[
  zfcore web framework for nim language
  This framework if free to use and to modify
  License: BSD
  Author: Amru Rosyada
  Email: amru.rosyada@gmail.com
  Git: https://github.com/zendbit
]#

#[
  This module auto export from zendFlow module
  export
    HttpContext, -> zfcore module
    router, -> zfcore module
    Router, -> zfcore module
    route, -> zfcore module
    Route, -> zfcore module
    asyncdispatch, -> stdlib module
    zfblast, -> zf blast implementation of async http server with openssl
    tables, -> stdlib module
    formdata, -> zfcore module
    strtabs, -> stdlib module
    uri3, -> nimble package
    strutils, -> stdlib module
    times, -> stdlib module
    os, -> stdlib module
    Settings, -> zfcore module
    settings, -> zfcore module
    AsyncSocket, -> stdlib module
    asyncnet -> stdlib module
    zfplugs -> zfcore plugins
    stdext -> nim extended standard library
    zfmacros -> zfcore macros helper
]#

include prelude
# layout example
import layout
# test example with route
import example

#[
 configuration:
 copy settings.json.example as settings.json

 this is the new fashion of the zendflow framework syntax, make it easy
 and reduce defining multiple time of callback procedures
 this new syntax not break the old fashion, we only add macros and modify the syntax
 on compile time


 Some Important note
 inside routes
 routes:
   get "/hello":
     # in here we can call HttpContext
     # HttpContext is unique object that heandle client request and response
     # HttpContext containts:
     # ws (WebSocket):
     #   ws is ctx.webSocket shorthand
     # req (Request):
     #   req is ctx.request shorthand
     # res (Response):
     #   res is ctx.response shorthand
     # params (table[string, string]):
     #   params is ctx.params shorthand
     #   this will contains data request parameter from client
     #   - key value of query string
     #   - key value of form url encoded
     # reParams (table[string, @[string]]):
     #   reParams is ctx.reParams shorthand
     #   this will contains pattern matching on the url segments
     # formData (FormData):
     #   formData is ctx.formData shorthand
     #   this will handle form data multipart including uploaded data
     # json (JsonNode):
     #   json is ctx.json shorthand
     #   this will handle application/json request from client
     

     # you can response to client with following type response:
     # HttpCode.resp("body response", httpheaders)
     # HttpCode is HttpCode value from the nim httpcore standard library
     # for example we want to reponse with Http200
     # Http200.resp("Hello World")
     # 
     # the default response type is text/plain
     # for html response use
     # Http200.respHtml("This is html content")
     #
     # for json response you only need to pas JsonNode object to the resp
     # Http200.resp(%*{"Hello": "World"})
     #
     # for send redirection web can use respRedirect
     # Http200.respRedirect("https://google.com")
     #
]#

routes:
  # render / to display default page for /
  get "/":
    Http200.respHtml(layout.indexLayout)

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
  # - capture regex will return list of match and can be access using ctx.reParams
  # - if we want to capture segment parameter we can use <param_to_capture>
  #   in this case we use <name>
  # - <name> will capture segment value in there as name,
  #   we can access param value and query string in HttpCtx.params["name"] or other param name
  get "/home/<ids:re[([0-9]+)_([0-9]+)]>/<name>":
    echo "Welcome home"
    # capture regex result from the url
    echo reParams["ids"]
    # capture <name> value parameter from the url
    echo params["name"]
    # we can also set custom header for the response
    # using ctx.responseHeaders.add("header kye", "header value")
    res.headers.add("Content-Type", "text/plain")
    Http200.respHtml("Hello World get request")

  #get "/home/<id>/<name>":
  #  echo ctx.params["name"]
  #  echo ctx.params["id"]
  #  resp(Http200, "Ok")

  get "/home/<id>":
    # capture the <id> from the path
    echo params["id"]
    Http200.resp("Hello World patch request")

  patch "/home/<id>":
    # capture the <id> from the path
    echo params["id"]
    Http200.resp("Hello World patch request")

  delete "/home/<id>":
    # capture the <id> from the path
    echo params["id"]
    Http200.resp("Hello World delete request")

  put "/home/<id>":
    # capture the <id> from the path
    echo params["id"]
    Http200.resp("Hello World put request")

  head "/home/<id>":
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

  emitServer()
