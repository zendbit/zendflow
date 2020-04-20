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
]#

import
    zfcore/zendFlow,
    server/servercodehere

# increase the maxBody to handle large upload file
# value in bytes
#[
    ssl example

let zf = newZendFlow(
    newSettings(
        appRootDir = getCurrentDir(),
        port = 8080,
        address = "0.0.0.0",
        debug = false,
        keepAliveMax = 100,
        keepAliveTimeout = 15,
        sslSettings = newSslSettings(
            certFile = joinPath("ssl", "certificate.pem"),
            keyFile = joinPath("ssl", "key.pem"),
            verify = false,
            port = Port(8443)
        )))
]#

#[
let zf = newZendFlow(
    newSettings(
        appRootDir = getCurrentDir(),
        port = 8080,
        address = "0.0.0.0",
        debug = true,
        keepAliveMax = 100,
        keepAliveTimeout = 15))
]#

# it will load default settings
# you can use settings.json confuguration
# by renaming the settings.json.example to settings.json
let zf = newZendFlow()

# handle before route middleware
zf.r.beforeRoute(proc (ctx: HttpCtx): Future[bool] {.async.} =
    # before Route here
    # you can filter the context request here before route happen
    # use full if we want to filtering the domain access or auth or other things that fun :-)
    # make sure if call response directly from middleware must be call return true for breaking the pipeline:
    #   ctx.resp(Http200, "Hello World get request"))
    #   return true
    )

# handle after route middleware
# this will execute right before dynamic route response to the server
zf.r.afterRoute(proc (ctx: HttpCtx, route: Route): Future[bool] {.async.} =
    # after Route here
    # you can filter the context request here after route happen
    # use full if we want to filtering the domain access or auth or other things that fun :-)
    # make sure if call response directly from middleware must be call return true for breaking the pipeline:
    #   ctx.resp(Http200, "Hello World get request"))
    #   return true
    )

# this static route wil serve under
# all static resource will serve under / uri path
# address:port/
# example address:port/style/*.css
# if you custumize the static route for example zf.r.static("/public")
# it will serve with address:port/public/
# we can retrieve using address:port/public/style/*.css
zf.r.static("/")

# web socket example
zf.r.get("/ws", proc (ctx: HttpCtx): Future[void] {.async.} =
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
                        1,
                        WSOpCode.TextFrame.uint8,
                        "This is from the endpoint :-)")
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
    )

# using regex for matching the request
# the regex is regex match like in pcre standard like regex on python, perl etc
# <ids:re[([0-9]+)_([0-9]+)]:len[2]>
# - the ids wil capture as parameter name
# - the len[2] is for len for capturing in this case in the () bracket, will capture ([0-9]+) twice
# - if only want to capture one we must exactly match len[n] with number of () capturing bracket
# - capture regex will return list of match and can be access using ctx.reParams
# - if we want to capture segment parameter we can use <param_to_capture> in this case we use <name>
# - <name> will capture segment value in there as name, we can access param value and query string in HttpCtx.params["name"] or other param name
zf.r.get("/home/<ids:re[([0-9]+)_([0-9]+)]:len[2]>/<name>", proc (
    ctx: HttpCtx): Future[void] {.async.} =
    echo "Welcome home"
    # capture regex result from the url
    echo ctx.reParams["ids"]
    # capture <name> value parameter from the url
    echo ctx.params["name"]
    # we can also set custom header for the response using ctx.responseHeaders.add("header kye", "header value")
    ctx.response.headers.add("Content-Type", "text/plain")
    ctx.resp(Http200, "Hello World get request"))

zf.r.get("/", proc (
    ctx: HttpCtx): Future[void] {.async.} =
    # set cookie
    let cookie = {"age": "25", "user": "john"}.newStringTable

    # cookie also has other parameter:
    # domain: string = "" -> default
    # path: string = "" -> default
    # expires: string = "" -> default
    # secure: bool = false -> default
    ctx.setCookie(cookie)

    # get coockie value:
    #   var cookie = ctx.getCookie() -> will return StringTableRef. Read nim strtabs module
    #   var age = cookie.getOrDefault("age")
    #   var user = cookie.getOrDefault("user")

    # if you want to clear the cookie you need to retrieve the cookie then pass the result to the clear cookie
    # clear cookie:
    #   var cookie = ctx.getCookie()
    #   ctx.clearCookie(cookie)

    # set default to redirect to index.htmo
    ctx.respRedirect("/index.html"))

# accept request with /home/123456
# id will capture the value 12345
zf.r.post("/home/<id>", proc (ctx: HttpCtx): Future[void] {.async.} =
    # if we post as application url encoded, the field data key value will be in the ctx.params
    # we can access using ctx.params["the name of the params"]
    # if we post as multipars we can capture the form field and files uploded in ctx.formData
    # - access field form data using ctx.formData.getField("fieldform_name") will return FieldData object
    # - access file form data using ctx.formData.getFileByName("name") will return FileData object
    # - access file form data using ctx.formData.getFileByFilename("file_name") will return FileData object
    # - all uploded file will be in the tmp dir for default, you can move the file to the destination file or dir by call
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
    ctx.resp(Http200, HelloWorld().printHelloWorld))

zf.r.patch("/home/<id>", proc (ctx: HttpCtx): Future[void] {.async.} =
    # capture the <id> from the path
    echo ctx.params["id"]
    ctx.resp(Http200, "Hello World patch request"))

zf.r.delete("/home/<id>", proc (ctx: HttpCtx): Future[void] {.async.} =
    # capture the <id> from the path
    echo ctx.params["id"]
    ctx.resp(Http200, "Hello World delete request"))

zf.r.put("/home/<id>", proc (ctx: HttpCtx): Future[void] {.async.} =
    # capture the <id> from the path
    echo ctx.params["id"]
    ctx.resp(Http200, "Hello World put request"))

zf.r.head("/home/<id>", proc (ctx: HttpCtx): Future[void] {.async.} =
    # capture the <id> from the path
    echo ctx.params["id"]
    ctx.resp(Http200, "Hello World head request"))

# serve the zendflow
zf.serve()
