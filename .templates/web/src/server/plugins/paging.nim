import
  uri3,
  json,
  math,
  strutils

proc genPaging*(data: JsonNode, url: Uri3, perPage: int64, numData: int64): JsonNode =
  let limit = url.getQuery("perPage", "20").parseBiggestInt
  let currentPage = url.getQuery("page", "1").parseBiggestInt
  result = %*{
    "pageData": data,
    "nextPage": "",
    "prevPage": "",
    "numPage": 0,
    "page": 1,
    "numData": 0,
    "lastPage": "",
    "firstPage": ""}

  if not data.isNil and data.kind == JsonNodeKind.JArray:
    if currentPage > 0:
      result["page"] = %currentPage

    if numData > limit:
      let numPage = (numData.float64 / limit.float64).ceil().int64
      result["numData"] = %numData
      result["numPage"] = %numPage
      if currentPage < numPage and currentPage > 1:
        let nextPage = currentPage * limit
        url.setQuery("page", $(currentPage + 1))
        result["nextPage"] = % $url
        
        url.setQuery("page", $(currentPage - 1))
        result["prevPage"] = % $url

      url.setQuery("page", $numPage)
      result["lastPage"] = % $url

      url.setQuery("page", "1")
      result["firstPage"] = % $url
