import std/asyncdispatch
import allographer/connection
import ./env


let rdb* = dbOpen(
  SurrealDB, # SQLite3 or MySQL or MariaDB or PostgreSQL or SurrealDB
  namespace = "main",
  database = "main",
  user = "user",
  password = "pass",
  host = "http://surreal",
  port = 8000,
  maxConnections = 1,
  timeout = 30,
  shouldDisplayLog = true,
  shouldOutputLogFile = false,
  logDir = "./logs",
).waitFor()
