import nicp_cdk
import ./controller

proc infoForDb*() {.update.} = discard controller.infoForDb()
proc createTodo*() {.update.} = discard controller.createTodo()
proc listTodos*() {.update.} = discard controller.listTodos()
