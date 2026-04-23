import std/asyncdispatch
import allographer/query_builder
import allographer/schema_builder
from ../../../config/database import testRdb


proc createTable*() {.async.} =
  rdb.create(
    table("sample", [
      Column.increments("id"),
      Column.string("name"),
    ]),
  )
