module type T = sig
  val convert : ?from:[`ISO_8859_1 | `UTF_8 | `UTF_16 | `UTF_16LE | `UTF_16BE] -> string -> string
end

module Naive : T = struct
  let convert ?from:_ s = s
end
