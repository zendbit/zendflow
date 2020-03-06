#[
    Helper for fluent JsObject
    newJObj()
        .add("key", 12345)
        .add("key2", "value")
        .add("key3, newJObj()
            .add("nestedKye", "value"))
]#
import
    jsffi

type
    JObj = ref object of JsObject

proc newJObj*(): JObj =
    return JObj()

proc add*(self: JObj, key: string, value: auto): JObj =
    self[key.cstring] = toJs(value)
    return self
