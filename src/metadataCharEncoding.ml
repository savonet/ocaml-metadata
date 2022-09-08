module type T = sig
  val convert : [`ISO8859 | `UTF8 | `UTF16 | `UTF16LE | `UTF16BE | `Auto] -> string -> string
end

module Naive : T = struct
  let convert _ s = s
end
