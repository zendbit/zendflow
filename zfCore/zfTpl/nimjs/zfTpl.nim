import init

document.body.innerHTML = """
<div id="app">
    {{ message }}
</div>
"""

var a = newJsObject()
a.el = "#app".cstring
a.data = newJsObject()
a.data.message = "Hello Vue".cstring
var app = vue(a)
