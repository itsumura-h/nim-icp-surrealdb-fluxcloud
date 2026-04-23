import std/json

type TodosTable* = object
  ## todos
  completed*: bool
  content*: string
  index*: int
  principal*: string
  title*: string


type SampleTable* = object
  ## sample
