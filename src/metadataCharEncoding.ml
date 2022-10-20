module type T = sig
  val convert : ?source:[`ISO_8859_1 | `UTF_8 | `UTF_16 | `UTF_16LE | `UTF_16BE] -> string -> string
end

module Naive : T = struct
  let convert ?source:_ s = s
end
