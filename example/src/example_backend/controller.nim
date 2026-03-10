import std/strformat
import nicp_cdk
import ../../../src/dc_stack_db

proc infoForDb*() {.async.} =
  let query = "INFO FOR DB;"
  let response = await exec(query)
  reply(response)


proc createTodo*() {.async.} =
  let caller = Msg.caller().text
  let request = Request.new()
  let todo = request.getStr(0)
  let query = &"CREATE todo SET principal = '{caller}', title = '{todo}';"
  let response = await exec(query)
  reply(response)


proc listTodos*() {.async.} =
  let caller = Msg.caller().text
  let query = &"SELECT * FROM todo WHERE principal = '{caller}';"
  let response = await exec(query)
  let responseObj = response.parseRecord()
  echo responseObj
  var titleList: seq[string] = @[]
  for row in responseObj[0]["result"].items():
    titleList.add(row["title"].getStr())
  reply(titleList)
