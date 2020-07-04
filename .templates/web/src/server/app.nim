#[
  ZendFlow web framework for nim language
  This framework if free to use and to modify
  License: BSD
  Author: Amru Rosyada
  Email: amru.rosyada@gmail.com
  Git: https://github.com/zendbit
]#

#[
  This module auto export from zendFlow module
  export
    HttpCtx, -> zfcore module
    HttpCtx, -> zfcore module
    router, -> zfcore module
    Router, -> zfcore module
    route, -> zfcore module
    Route, -> zfcore module
    asyncdispatch, -> stdlib module
    zfblast, -> zf blast implementation of async http server with openssl
    tables, -> stdlib module
    formData, -> zfcore module
    FormData, -> zfcore module
    packedjson, -> zfcore module (unpure)
    strtabs, -> stdlib module
    uri3, -> nimble package
    strutils, -> stdlib module
    times, -> stdlib module
    os, -> stdlib module
    Settings, -> zfcore module
    settings, -> zfcore module
    AsyncSocket, -> stdlib module
    asyncnet -> stdlib module
    zfMacros -> zfcore macros helper
]#

import
  zfcore,
  example

#
# configuration:
# copy settings.json.example as settings.json
#

# this is the new fashion of the zendflow framework syntax, make it easy
# and reduce defining multiple time of callback procedures
# this new syntax not break the old fashion, we only add macros and modify the syntax
# on compile time
zf:
  routes:
    # websocket example :-)
    get "/ws":
      # ctx instance of HttpCtx exposed here :-)
      let ws = ctx.webSocket
      if not isNil(ws):
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
    # <ids:re[([0-9]+)_([0-9]+)]:len[2]>
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
    get "/home/<ids:re[([0-9]+)_([0-9]+)]:len[2]>/<name>":
      echo "Welcome home"
      # capture regex result from the url
      echo ctx.reParams["ids"]
      # capture <name> value parameter from the url
      echo ctx.params["name"]
      # we can also set custom header for the response
      # using ctx.responseHeaders.add("header kye", "header value")
      ctx.response.headers.add("Content-Type", "text/plain")
      resp(Http200, "Hello World get request")

    #get "/home/<id>/<name>":
    #  echo ctx.params["name"]
    #  echo ctx.params["id"]
    #  resp(Http200, "Ok")

    # accept request with /home/123456
    # id will capture the value 12345
    post "/home/<id>":
      # if we post as application url encoded, the field data key value will be in the ctx.params
      # we can access using ctx.params["the name of the params"]
      # if we post as multipars we can capture the form field and files uploded in ctx.formData
      # - access field form data using ctx.formData.getField("fieldform_name")
      #   will return FieldData object
      # - access file form data using ctx.formData.getFileByName("name")
      #   will return FileData object
      # - access file form data using ctx.formData.getFileByFilename("file_name")
      #   will return FileData object
      # - all uploded file will be in the tmp dir for default,
      #   you can move the file to the destination file or dir by call
      # - let uploadedFile = ctx.formData.getFileByFilename("file_name")
      # - if not isNil(uploadedFile): uploadedFile.moveFileTo("the_destination_file_with_filename")
      # - if not isNil(uploadedFile): uploadedFile.moveFileToDir("the_destination_file_to_dir")
      # - or we can iterate the field
      #       for field in ctx.formData.getFields():
      #           echo field.name
      #           echo field.contentDisposition
      #           echo field.content
      # - also capture uploaded file using
      #       for file in ctx.formData.getFiles():
      #           echo file.name
      #           echo file.contentDisposition
      #           echo file.content -> is absolute path of the file in tmp folder
      #           echo file.filename
      #           echo file.contentType
      #
      #  - for more information you can also check documentation form the source:
      #       zfCore/zf/HttpCtx.nim
      #       zfCore/zf/formData.nim
      #
      # capture the <id> from the path
      echo ctx.params["id"]
      resp(Http200, HelloWorld().printHelloWorld)

    patch "/home/<id>":
      # capture the <id> from the path
      echo ctx.params["id"]
      resp(Http200, "Hello World patch request")

    delete "/home/<id>":
      # capture the <id> from the path
      echo ctx.params["id"]
      resp(Http200, "Hello World delete request")

    put "/home/<id>":
      # capture the <id> from the path
      echo ctx.params["id"]
      resp(Http200, "Hello World put request")

    head "/home/<id>":
      # capture the <id> from the path
      echo ctx.params["id"]
      resp(Http200, "Hello World head request")

  # before Route here
  # you can filter the context request here before route happen
  # use full if we want to filtering the domain access or auth or other things that fun :-)
  # make sure if call response directly from middleware
  # require call return true for breaking the pipeline:
  #   resp(Http404, "page not found"))
  #   return true
  beforeRoute:
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
  afterRoute:
    # ctx instance of HttpCtx exposed here :-)
    # route instance of Route exposed here :-)
    #
    echo "Hello World"

