import std/asyncdispatch
import std/json
import allographer/query_builder
import allographer/schema_builder
from ../../../config/database import rdb

proc createTable*() {.async.} =
  rdb.create(
    table("todos", [
      Column.increments("index"),
      Column.string("principal").index(),
      Column.string("title"),
      Column.string("content"),
      Column.boolean("completed").default(false)
    ]),
  )

  echo rdb.raw("INFO FOR TABLE todos").info().await
