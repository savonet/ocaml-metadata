type recode =
  ?source:[ `ISO_8859_1 | `UTF_8 | `UTF_16 | `UTF_16LE | `UTF_16BE ] ->
  ?target:[ `UTF_8 | `UTF_16 | `UTF_16LE | `UTF_16BE ] ->
  string ->
  string

module type T = sig
  val convert : recode
end

module Naive : T
