import std/asyncdispatch
import std/strutils
import std/options
import nicp_cdk
import nicp_cdk/canisters/management_canister


proc toBytes(value: string): seq[uint8] =
  result = newSeq[uint8](value.len)
  for i, c in value:
    result[i] = uint8(ord(c))

proc exec*(query:string) {.async.} =
  let body = query.toBytes()
  let request = HttpRequestArgs(
    url: "http://surreal:8000",
    httpMethod: HttpMethod.Post,
    headers: @[],
    body: some(body),
    transform: none(HttpTransform),
    is_replicated: some(false),
  )
  let response = await ManagementCanister.httpRequest(request)
  echo response.getTextBody()