# ZendFlow
High performance asynchttpserver and web framework for nim language. This is ready for production but we need to run it under proxy :-) better using nginx

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

- Create new project
```
nim zf.nims new mysite
```

the command above will create mysite app under the projects directory "projects/mysite"

- Install project dependencies
```
nim zf.nims install mysite deps
```

- Run mysite app
```
nim zf.nims run mysite
```

the command above will run mysite app on default port 8080 and bind address 0.0.0.0,
open [http://localhost:8080](http://localhost:8080) you will be redirect to [http://localhost:8080/index.html](http://localhost:8080/index.html)

**the run command will wait from user input, use "enter/return" key to recompile updated source or use "q" then hit enter/return to quit the run dev mode and terminate the server**

## Zendflow Core structure

- zf.nims

This file is nimscript to manage the zendflow projects, available command:
```
nim zf.nims new appname -> create new projects under projects directory
nim zf.nims install appname deps -> install application depedencies, to add depedency you can changes the deps file or directly from nimble command
nim zf.nims run appname -> this will run the appname, run command will wait user input: return/enter will recompile changes source, to quit type "q" then hit return/enter
```

- zfCore

This folder contain zenflow core engine and project template.
The zf folder contains .nim file of zendflow building block also contain folder unpure, the unpure folder will contains unpure lib (thirdparty library)

zf folder contains:
1. ctxReq.nim
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

## Zendflow Application structure

When we create new project using zf.nims new appname, the zf nimscript will create the appname to the projects directory.
The application sturcure will contain:

1. app_name{App.nim}

All application starting point will be end with {App.nim}, for example we create "mysite" application then the application
will changed to "mysileApp".nim, the appname{App.nim} is convention and should not be changes.

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

import ../../zfCore/zf/zendFlow

# increase the maxBody to handle large upload file
# value in bytes
let zf = newZendFlow(
    newSettings(
        appRootDir = getCurrentDir(),
        port = 8080,
        address = "0.0.0.0",
        reuseAddr = true,
        reusePort = false,
        maxBody = 8388608))

# handle before route middleware
zf.r.beforeRoute(proc (ctx: CtxReq): Future[bool] {.async.} =
    # before Route here
    # you can filter the context request here before route happen
    # use full if we want to filtering the domain access or auth or other things that fun :-)
    # make sure if call response directly from middleware must be call return true for breaking the pipeline:
    #   await ctx.resp(Http200, "Hello World get request"))
    #   return true
    )

# handle after route middleware
# this will execute right before dynamic route response to the server
zf.r.afterRoute(proc (ctx: CtxReq, route: Route): Future[bool] {.async.} =
    # after Route here
    # you can filter the context request here after route happen
    # use full if we want to filtering the domain access or auth or other things that fun :-)
    # make sure if call response directly from middleware must be call return true for breaking the pipeline:
    #   await ctx.resp(Http200, "Hello World get request"))
    #   return true
    )

# this static route wil serve under
# all static resource will serve under /s uri path
# address:port/s/
# example address:port/s/style/*.css
# if you custumize the static route for example zf.r.static("/public")
# it will serve with address:port/s/public/
# we can retrieve using address:port/s/public/style/*.css
zf.r.static("/")

# using regex for matching the request
# the regex is regex match like in pcre standard like regex on python, perl etc
# <ids:re[([0-9]+)_([0-9]+)]:len[2]>
# - the ids wil capture as parameter name
# - the len[2] is for len for capturing in this case in the () bracket, will capture ([0-9]+) twice
# - if only want to capture one we must exactly match len[n] with number of () capturing bracket
# - capture regex will return list of match and can be access using ctx.reParams
# - if we want to capture segment parameter we can use <param_to_capture> in this case we use <name>
# - <name> will capture segment value in there as name, we can access param value and query string in ctxReq.params["name"] or other param name
zf.r.get("/home/<ids:re[([0-9]+)_([0-9]+)]:len[2]>/<name>", proc (
        ctx: CtxReq): Future[void] {.async.} =
    echo "Welcome home"
    # capture regex result from the url
    echo ctx.reParams["ids"]
    # capture <name> value parameter from the url
    echo ctx.params["name"]
    # we can also set custom header for the response using ctx.responseHeaders.add("header kye", "header value")
    ctx.responseHeaders.add("Content-Type", "text/plain")
    await ctx.resp(Http200, "Hello World get request"))

zf.r.get("/", proc (
        ctx: CtxReq): Future[void] {.async.} =
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
    await ctx.respRedirect("/index.html"))

# accept request with /home/123456
# id will capture the value 12345
zf.r.post("/home/<id>", proc (ctx: CtxReq): Future[void] {.async.} =
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
    #       for field in ctx.getFields():
    #           echo field.name
    #           echo field.contentDisposition
    #           echo field.content
    # - also capture uploaded file using
    #       for file in ctx.getFiles():
    #           echo file.name
    #           echo file.contentDisposition
    #           echo file.content -> is absolute path of the file in tmp folder
    #           echo file.filename
    #           echo file.contentType
    #
    #  - for more information you can also check documentation form the source:
    #       zfCore/zf/ctxReq.nim
    #       zfCore/zf/formData.nim
    #
    # capture the <id> from the path
    echo ctx.params["id"]
    await ctx.resp(Http200, "Hello World post request"))

zf.r.patch("/home/<id>", proc (ctx: CtxReq): Future[void] {.async.} =
    # capture the <id> from the path
    echo ctx.params["id"]
    await ctx.resp(Http200, "Hello World patch request"))

zf.r.delete("/home/<id>", proc (ctx: CtxReq): Future[void] {.async.} =
    # capture the <id> from the path
    echo ctx.params["id"]
    await ctx.resp(Http200, "Hello World delete request"))

zf.r.put("/home/<id>", proc (ctx: CtxReq): Future[void] {.async.} =
    # capture the <id> from the path
    echo ctx.params["id"]
    await ctx.resp(Http200, "Hello World put request"))

zf.r.head("/home/<id>", proc (ctx: CtxReq): Future[void] {.async.} =
    # capture the <id> from the path
    echo ctx.params["id"]
    await ctx.resp(Http200, "Hello World head request"))

# serve the zendflow
zf.serve()
```

2. deps file

This file is contain depedencies of the application, you can add here and install using zf.nims install appname deps
or directly using nimble package to install the depedencies

3. nimjs folder

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

Thats it, feel free to modify and pull request if you have any idea, also this is the public domain we can share or you can cantact me on my email [amru.rosyada@amil.com](amru.rosyada@amil.com) to discuss further.

This is production ready :-), feel free to send me a bug to solve.

Need todo:
- ssl support (this not mandatory, we can done to run zendflow under nginx)
- orm integration
- websocket
- rpc
