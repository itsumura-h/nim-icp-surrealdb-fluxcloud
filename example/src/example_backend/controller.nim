import nicp_cdk
import ../../../src/dc_stack_db

proc migrate*() {.async.} =
  let query = "INFO FOR DB;"
  let response = await exec(query)
  reply(response)
