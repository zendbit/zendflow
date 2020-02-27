#[
    ZendFlow web framework for nim language
    This framework if free to use and to modify
    License: BSD
    Author: Amru Rosyada
    Email: amru.rosyada@gmail.com
    Git: https://github.com/zendbit
]#

import ../../zfCore/zf/zendFlow

let zf = newZendFlow()

# handle before route middleware
zf.r.beforeRoute(proc (ctx: CtxReq): Future[void] {.async.} =
    # before Route here
    # you can filter the context request here before route happen
    # use full if we want to filtering the domain access or auth or other things that fun :-)
    )

# handle after route middleware
# this will execute right before dynamic route response to the server
zf.r.afterRoute(proc (ctx: CtxReq, route: Route): Future[void] {.async.} =
    # after Route here
    # you can filter the context request here after route happen
    # use full if we want to filtering the domain access or auth or other things that fun :-)
    )

# this static route wil serve under
# all static resource will serve under /
# example address:port/style/*.css
# if you custumize the static route for example zf.r.static("/public")
# it will serve with address:port/public/
# we can retrieve using address:port/public/style/*.css
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

# will serve root get
zf.r.get("/", proc (
        ctx: CtxReq): Future[void] {.async.} =
    echo "Welcome home"
    await ctx.resp(Http200, "Hello World get request"))

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
