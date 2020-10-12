import example
import zfcore

routes:
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
    echo params["id"]
    Http200.respHtml(HelloWorld().printHelloWorld)
