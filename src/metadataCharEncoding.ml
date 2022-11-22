module type T = sig
  val convert : ?source:[`ISO_8859_1 | `UTF_8 | `UTF_16 | `UTF_16LE | `UTF_16BE] -> string -> string
end

module Naive : T = struct
  let convert ?source s =
    let source = match source with None -> `UTF_8 | Some x -> x in
    let buf = Buffer.create 10 in
    match source with
    | (`UTF_16LE | `UTF_16BE) as source ->
       let get_char =
         match source with
         | `UTF_16LE -> String.get_utf_16le_uchar
         | `UTF_16BE -> String.get_utf_16be_uchar
       in
       let len = String.length s in
       let rec f pos =
         if pos = len then
           Buffer.contents buf
         else
           let d = get_char s pos in
           let c = Uchar.utf_decode_uchar d in
           Buffer.add_utf_8_uchar buf c;
           f (pos + Uchar.utf_decode_length d)
       in
       f 0
    | `UTF_8 -> s
    | _ -> s
end
