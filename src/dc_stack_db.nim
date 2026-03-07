import std/asyncdispatch
import std/strutils
import std/options
import std/base64
import nicp_cdk
import nicp_cdk/canisters/management_canister


proc toBytes(value: string): seq[uint8] =
  result = newSeq[uint8](value.len)
  for i, c in value:
    result[i] = uint8(ord(c))

proc exec*(query:string):Future[string] {.async.} =
  let body = query.toBytes()
  let request = HttpRequestArgs(
    url: "http://surreal:8000/sql",
    httpMethod: HttpMethod.Post,
    headers: @[
      HttpHeader(name: "Surreal-NS", value: "main"),
      HttpHeader(name: "Surreal-DB", value: "main"),
      HttpHeader(name: "Authorization", value: "Basic " & base64.encode("user:pass")),
      HttpHeader(name: "Content-Type", value: "text/plain"),
    ],
    body: some(body),
    transform: none(HttpTransform),
    is_replicated: some(false),
  )
  let response = await ManagementCanister.httpRequest(request)
  let responseBody = response.getTextBody()
  return responseBody.strip()
