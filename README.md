# ZendFlow
High performance asynchttpserver and web framework for nim language. This is ready for production :-) better run under nginx proxy. **for this release not supported windows, need to changes the zf.nims shell cmd to support windows system**

start from version 1.0.6 websocket ready

***the asynchttpserver already migrate to zfblast server*** our http server implementaion using asyncnet with openssl ready. Using zendflow need to installed openssl and the compile flag default to -d:ssl

## Install Nim Lang

Follow this nim language installation and setup [Nim Language Download](https://nim-lang.org/install.html)

## Clone zendflow repo and quick start
```
git clone https://github.com/zendbit/zendflow.git
```

goto zendflow dir
```
cd zendflow
```

inside zendflow you can find zf.nims file, this file is command line to manage the zendflow project.
***we port zf.nims to zf.sh, for the next release we will only maintain the shell script :-)***

- Create new project
```
./zf.sh new mysite
```

the command above will create mysite app under the projects directory "projects/mysite"

- Install project dependencies
```
./zf.sh install mysite deps
```

- Run mysite app
```
./zf.sh run mysite
```

the command above will run mysite app on default port 8080 and bind address 0.0.0.0,
open [http://localhost:8080](http://localhost:8080) you will be redirect to [http://localhost:8080/index.html](http://localhost:8080/index.html)

- ***Command summary***
```
./zf.sh --help

Usage:
------------------------------------------------------
Create new app        : ./zf.sh new appname
Install app depedency : ./zf.sh install-deps appname
Build app             : ./zf.sh build appname
Run the app           : ./zf.sh run appname
Set default app       : ./zf.sh set-default appname
List available app    : ./zf.sh list-apps
View default app      : ./zf.sh default-app
Delete app            : ./zf.sh delete appname
------------------------------------------------------
If default app already set using set-default,
simply call without app name
Install app depedency : ./zf.sh install-deps
Build app             : ./zf.sh build
Run the app           : ./zf.sh run
------------------------------------------------------
```

**the run command will wait from user input, use "enter/return" key to recompile updated source or use "q" then hit enter/return to quit the run dev mode and terminate the server**

## Zendflow Core structure

- zf.nims ***we port the nimscript to zf.sh, for the next release we only maintain the shell script :-)***

This file is nimscript to manage the zendflow projects, available command:
```
./zf.sh new appname -> create new projects under projects directory
./zf.sh install appname deps -> install application depedencies, to add depedency you can changes the deps file or directly from nimble command
./zf.sh run appname -> this will run the appname, run command will wait user input: return/enter will recompile changes source, to quit type "q" then hit return/enter
```

- **zfCore (The zfcore moved to nimble package [zfcore](https://nimble.directory/pkg/zfcore))**

This package contain core engine. The zfcore .nim file of zfcore building block also contain folder unpure, the unpure folder will contains unpure lib (thirdparty library)

zfCore contains:
1. ctxReq.nim -> replaced with httpContext.nim this is implementation from zfblast server ()
this will handle request context also contains the response context
```
#[
    The field is widely used the asynchttpserver Request object but we add some field to its:
        url -> in ZendFlow we user uri3 from the nimble package
        params -> is table of the captured query string and path segment
        reParams -> is table of the captured regex match with the segment
        formData -> is FormData object and will capture if we use the multipart form
        json -> this will capture the application/json body from the post/put/patch method
        settings -> this is the shared settings
        responseHeader -> headers will send on response to user
]#
CtxReq will not used again and replaced with HttpCtx type
type
    CtxReq* = ref object
        client*: AsyncSocket
        reqMethod*: HttpMethod
        headers*: HttpHeaders
        protocol*: tuple[orig: string, major, minor: int]
        url*: Uri3
        hostname*: string
        body*: string
        params*: Table[string, string]
        reParams*: Table[string, seq[string]]
        formData*: FormData
        json*: JsonNode
        settings*: Settings
        responseHeaders*: HttpHeaders
        
Replaced with HttpCtx type
type
    HttpCtx* = ref object of HttpContext
        params*: Table[string, string]
        reParams*: Table[string, seq[string]]
        formData*: FormData
        json*: JsonNode
        settings*: Settings
        
Where HttpContext is zfblast context
type
    HttpContext* = ref object of RootObj
        # Request type instance
        request*: Request
        # client asyncsocket for communicating to client
        client*: AsyncSocket
        # Response type instance
        response*: Response
        # send response to client, this is bridge to ZFBlast send()
        send*: proc (ctx: HttpContext): Future[void]
        # Keep-Alive header max request with given persistent timeout
        # read RFC (https://tools.ietf.org/html/rfc2616)
        # section Keep-Alive and Connection
        # for improving response performance
        keepAliveMax*: int
        # Keep-Alive timeout
        keepAliveTimeout*: int
```
2. formData.nim

This will handle the formdata multipart and parse the form field and uploaded file

3. middleware.nim

This will handle the middleware of the engine, this contain before route and after route pipeline for filtering

4. mime.nim

This is database of mime file, not all mime file registered here, if the mime file not found then the mime will be application/octet-stream

5. route.nim

This file is model of the route

6. router.nim

This file will handle registered route, for example user register the get, put, push, patch, head, post, options method to the router.

7. settings.nim

This is the settings model for the zenflow application

8. viewRender.nim

This is experimental and should not be used

9. zendflow.nim

The is the starting building block

zfTpl Folder is the project template when we use zf.nims new appname

## Fluent validation

Starting from zfcore version 1.0.1 we added fluent validation

```
let validation = newFluentValidation()
    validation
        .add(newFieldData("username", ctx.params["username"])
            .must("Username is required.")
            .reMatch("([\w\W]+@[\w\W]+\.[\w])$", "Email format is not valid."))
        .add(newFieldData("password", ctx.params["password"])
            .must("Password is required.")
            .rangeLen(10, 255, "Min password length is 10, max is 255."))
            
access the validation result:
    validation.valids -> contain valids field on validation (Table[string, FieldData])
    validation.notValids -> contain notValids field on validation (Table[string, FieldDat])
```

## Zendflow Application structure

When we create new project using zf.nims new appname, the zf nimscript will create the appname to the projects directory.
The application sturcure will contain:

1. app_name{App.nim}

Each time new project creation inside each project will have settings.json.example, you can rename it as settings.json. The settings.json will load by app runtime start and will be populate to the project settings.
```
{
  "appRootDir": "",
  "keepAliveMax": 100,
  "keepAliveTimeout": 15,
  "maxBodyLength": 268435456,
  "debug": false,
  "http": {
    "port": 8080,
    "address": "0.0.0.0",
    "reuseAddress": true,
    "reusePort": false,
    "secure": {
      "cert": "ssl/certificate.pem",
      "key": "ssl/key.pem",
      "verify": true,
      "port": 8443
    }
  }
}

```

We can also add custom configuration into the settings.json, in this case we add example for postgresql settings and will be used later.
```
{
  "appRootDir": "",
  "keepAliveMax": 100,
  "keepAliveTimeout": 15,
  "maxBodyLength": 268435456,
  "debug": false,
  "http": {
    "port": 8080,
    "address": "0.0.0.0",
    "reuseAddress": true,
    "reusePort": false,
    "secure": {
      "cert": "ssl/certificate.pem",
      "key": "ssl/key.pem",
      "verify": true,
      "port": 8443
    }
  },
  "pgSqlConf": {
    "user": "admin",
    "password": "admin_pass",
    "database": "mydb",
    "host": "localhost"
  }
}
```

we can retrieve the configuration by import zfcore/zendFlow and use the zfJsonSettings() procedures, the zfJsonSettings() procedures will return json object
```
import zfcore/zendFlow

let pgSqlConf = zfJsonSettings().getOrDefault("pgSqlConf")
if not isNil(pgSqlConf):
    # retrieve the value
    # see the json decumentation from the nim lang
    let host = pgSqlConf{"host"}.getStr()
    let user = pgSqlConf{"user"}.getStr()
    let pass = pgSqlConf{"password"}.getStr()
    let db = pgSqlConf{"database"}.getStr()
```

All application starting point will be end with {App.nim}, for example we create "mysite" application then the application
will changed to "mysileApp".nim, the appname{App.nim} is convention and should not be changes.

From zfcore version 1.0.8 we implement some macros for helper and make easy to code. We wrap some complicated definition of initialization and routing.

for example on old fashion we use the:
```
let zf = new ZendFlow()

zf.r.beforeRoute(proc (ctx: HttpCtx): Future[bool] {.async.} =
    )

zf.r.afterRoute(proc (ctx: HttpCtx, route: Route): Future[bool] {.async.} =
    )
    
zf.r.static("/")

zf.r.get("/", proc (ctx: HttpCtx): Future[void] {.async.} =
    ctx.respRedirect("/index.html"))
    
zf.serve()
```

then we turn into this new fashion sintax wrapper, but still we can use the old fashion for backward compatibility
```
zf:
    beforeRoute:
        resp(Http200, "OK")
        # ctx instance available here
        # should call
        # return true if we want to break the pipeline
        
    afterRoute:
        resp(Http200, "OK")
        # ctx instance available here
        # route instance available here
        # should call
        # return true if we want to break the pipeline
       
    routes:
        static "/"
        get "/":
            # ctx instance available here
            respRedirect("/index.html")
            
serve()
```

Some method from ctx we wrapped in the routes
```
ctx.resp -> resp
ctx.respRedirect -> respRedirect
ctx.setCookie -> setCookie
ctx.getCookie -> getCookie
ctx.clearCookie -> clearCookie
```

After create the application this file will containts bunch of examples, just open the starting point file and you will gets:
```
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

import zfcore/ZendFlow

zf:
    # this will create instance of ZendFlow
    # and will accessible through zfInstance variable
    # handle before route middleware
    beforeRoute:
        # before Route here
        # you can filter the context request here before route happen
        # use full if we want to filtering the domain access or auth or other things that fun :-)
        # make sure if call response directly from middleware must be call return true for breaking the pipeline:
        #   resp(Http200, "Hello World get request")
        #   return true
        echo "before route block"

    # handle after route middleware
    # this will execute right before dynamic route response to the server
    afterRoute:
        # after Route here
        # you can filter the context request here after route happen
        # use full if we want to filtering the domain access or auth or other things that fun :-)
        # make sure if call response directly from middleware must be call return true for breaking the pipeline:
        #   resp(Http200, "Hello World get request")
        #   return true
        echo "after route block"

    routes:
        # this static route wil serve under
        # all static resource will serve under / uri path
        # address:port/
        # example address:port/style/*.css
        # if you custumize the static route for example zf.r.static("/public")
        # it will serve with address:port/public/
        # we can retrieve using address:port/public/style/*.css
        static "/"

        # web socket example
        get "/ws":
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
        # - <name> will capture segment value in there as name,
        #   we can access param value and query string in HttpCtx.params["name"] or other param name
        get "/home/<ids:re[([0-9]+)_([0-9]+)]:len[2]>/<name>":
            echo "Welcome home"
            # capture regex result from the url
            echo ctx.reParams["ids"]
            # capture <name> value parameter from the url
            echo ctx.params["name"]
            # we can also set custom header for the response using ctx.responseHeaders.add("header kye", "header value")
            ctx.responseHeaders.add("Content-Type", "text/plain")
            resp(Http200, "Hello World get request")

        get "/":
            # set cookie
            let cookie = {"age": "25", "user": "john"}.newStringTable

            # cookie also has other parameter:
            # domain: string = "" -> default
            # path: string = "" -> default
            # expires: string = "" -> default
            # secure: bool = false -> default
            setCookie(cookie)

            # get coockie value:
            #   var cookie = getCookie() -> will return StringTableRef. Read nim strtabs module
            #   var age = cookie.getOrDefault("age")
            #   var user = cookie.getOrDefault("user")

            # if you want to clear the cookie you need to retrieve the cookie then pass the result to the clear cookie
            # clear cookie:
            #   var cookie = getCookie()
            #   clearCookie(cookie)

            # set default to redirect to index.html
            respRedirect("/index.html")

        # accept request with /home/123456
        # id will capture the value 12345
        post "/home/<id>":
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
            ctx.resp(Http200, "Hello World post request")

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

# serve the zendflow
serve()
```

2. deps file

This file is contain depedencies of the application, you can add here and install using zf.nims install appname deps
or directly using nimble package to install the depedencies

3. nimjs folder (renamed to ***client*** folder make it easy to understand)

This will contains the appname{Js.nim}, will end up with {Js.nim}, this file is the nim application for the client side
and will compile to the "appname{Js.js}" file, the .js file wil be moved to the "www/private/compiled" folder. Then you can include the .js file into .html page. For example we include into index.html.

(the appname{App.nim} is convention and should not be changes.)

in the nimjs folder also contain lib folder, this lib is contain other code of nim source code for client side. In this example init.nim contains jffi to the "vue js library" and "jquery library"

"nimjs/lib/init.nim" contains:

```
# init.nim
import
    dom,
    jscore,
    asyncjs,
    jsffi

# import the document object and the console
#var document {.importc, nodecl.}: JsObject
var console* {.importc, nodecl.}: JsObject
# jsffi to initVue wrapper in index.html
# this map to function:
#
# Initialize the vue js
proc vue*(jsObject: JsObject): JsObject {.importcpp: "initVue(#)".}
# Initialize the jquery
proc jq*(selector: JsObject): JsObject {.importcpp: "initJq(#)".}
proc jq*(selector: Element): JsObject {.importcpp: "initJq(#)".}
proc jq*(selector: Document): JsObject {.importcpp: "initJq(#)".}
proc jq*(): JsObject {.importcpp: "initJq()".}

export
    dom,
    jscore,
    asyncjs,
    jsffi
```

appname{Js.nim} will compiled to appname{Js.js} to www/private/compiled

```
# appname{Js.nim} will compiled to appname{Js.js} to www/private/compiled
import
    lib/init,
    lib/jObj,
    strutils

# example call the jquery
# and append to the document body
jq(document.body).append(
    """
    <div id="app">
        {{ message }}
    </div>
    """)

# example using the vue js
# to interact with the layout
var a = newJObj()
    .add("el", "#app")
    .add("data", newJObj()
        .add("message", "Hello Vue"))
discard vue(a)

jq(document.body).append(document.body).append(
    """
    <div id="app-2">
    <span v-bind:title="message">
        Hover your mouse over me for a few seconds
        to see my dynamically bound title!
    </span>
    </div>
    """)

var b = newJObj()
    .add("el", "#app-2")
    .add("data", newJObj()
        .add("message", DateTime().toString()))
discard vue(b)

jq(document.body).append(document.body).append(
    """
    <div id="app-3">
    <span v-if="seen">Now you see me</span>
    </div>
    """)

var c = newJObj()
    .add("el", "#app-3")
    .add("data", newJObj()
        .add("seen", true))
discard vue(c)

jq(document.body).append(document.body).append(
    """
    <div id="app-4">
    <ol>
        <li v-for="todo in todos">
        {{ todo.text }}
        </li>
    </ol>
    </div>
    """)

var d = newJObj()
    .add("el", "#app-4")
    .add("data", newJObj()
        .add("todos", @[
            newJObj().add("text", "Learn nim"),
            newJObj().add("text", "Hack the nim")]))
discard vue(d)

jq(document.body).append(document.body).append(
    """
    <div id="app-5">
    <p>{{ message }}</p>
    <button v-on:click="reverseMessage">Reverse Message</button>
    </div>
    """)

var e = newJObj()
    .add("el", "#app-5")
    .add("data", newJObj()
        .add("message", "Hello vue from nim"))
    .add("methods", newJObj()
        .add("reverseMessage", proc (): cstring =
            let s = "Hello vue from nim".split(" ")
            var reverse: seq[string] = @[]
            for i in countdown(high(s), 0):
                reverse.add(s[i])
            return join(reverse, " ").cstring))
discard vue(e)

# also can call the console log from here :-)
console.log(e.methods.reverseMessage())

jq(document.body).append("<p>Test</p>")

# example call the ready state of the jquery
jq(document).ready(proc() =
    echo "ready state")

```

4. www folder

This folder contains the static resource, the www folder after create the project will contains:

*index.html*

This is the index.html for example of jffi "to vue js" and "jquery":

```
<html>

    <head>
        <meta charset="UTF-8">
        <link rel="stylesheet" type="text/css" href="/vendor/bootstrap/css/bootstrap.min.css">
    </head>

    <body>
    </body>

</html>

<script src="/vendor/vue/vue-2_6_11.js"></script>
<script src="/vendor/jquery/jquery-3.4.1.min.js"></script>
<script src="/vendor/bootstrap/js/bootstrap.min.js"></script>
<script src="/private/js/lib/init.js"></script>
<script src="/private/js/compiled/mysiteJs.js"></script>

```

on the above code we can see that before appname{Js.js} in this case mysiteJs.js load "/private/js/lib/init.js" to initialize the vue and jquery jsffi (will consume and map in "nimjs/lib/init.nim").

"/private/js/lib/init.js" code:

```
function initVue(obj)
{
    return new Vue(obj);
}

function initJq()
{
    return $();
}

function initJq(selector)
{
    return $(selector);
}

```

in the www folder contains vendor folder, this will contains the thirdpary library.

## How to deploy

To deploy we need the under projects folder only, for example web have application mysite under projects directory, we can deploy mysite directory to target system.

```
./zf.sh build
./mysiteApp
```

just in case want to develop
```
./zf.sh run -> run on interactive mode
```

Thats it, feel free to modify and pull request if you have any idea, also this is the public domain we can share or you can cantact me on my email [amru.rosyada@amil.com](amru.rosyada@amil.com) to discuss further.

This is production ready :-), feel free to send me a bug to solve.

Need todo:
- orm integration
- rpc

Done:
- ssl support (this not mandatory, we can done to run zendflow under nginx)
- web socket
