module type T = sig
  val convert : [`ISO_8859_1 | `UTF_8 | `UTF_16 | `UTF_16LE | `UTF_16BE | `Auto] -> string -> string
end

module Naive : T = struct
  let convert _ s = s
end
