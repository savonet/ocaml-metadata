open MetadataBase
module R = MetadataBase.Reader

let tagn =
  [
    ("\xa9nam", "title");
    ("\xa9ART", "artist");
    ("\xa9too", "encoder");
    ("\xa9day", "date");
    ("\xa9cpy", "copyright");
    ("\xa9alb", "album");
    ("\xa9des", "description");
    ("\xa9cmt", "comment");
  ]

let parse f : metadata =
  let len = R.int32_be f in
  if R.read f 4 <> "ftyp" then raise Invalid;
  R.drop f (len - 8);
  let ans = ref [] in
  let rec chunk l =
    let len = R.int32_be f in
    let tag = R.read f 4 in
    let tags = tag :: l in
    (match tags with
      | ["moov"]
      | ["udta"; "moov"]
      | ["meta"; "udta"; "moov"]
      | ["ilst"; "meta"; "udta"; "moov"]
      | [_; "ilst"; "meta"; "udta"; "moov"] ->
          let remaining = ref (len - 8) in
          if List.hd tags = "meta" then (
            R.drop f 4;
            remaining := !remaining - 4);
          (* version and flags for metadata *)
          while !remaining > 0 do
            remaining := !remaining - chunk (tag :: l)
          done
      | ["data"; tag; "ilst"; "meta"; "udta"; "moov"] -> (
          if len < 16 then raise Invalid;
          let data_type = R.int32_be f in
          let _ = R.read f 4 in
          let value = R.read f (len - 16) in
          match (data_type, List.assoc_opt tag tagn) with
            | 1, Some tag -> ans := (tag, value) :: !ans
            | 2, Some tag ->
                ans :=
                  ( tag,
                    MetadataCharEncoding.Naive.convert ~source:`UTF_16BE value
                  )
                  :: !ans
            | _ -> ())
      | _ -> R.drop f (len - 8));
    len
  in
  try
    while true do
      ignore (chunk [])
    done;
    assert false
  with _ -> List.rev_map (fun (k, v) -> (k, `String v)) !ans

let parse_file = R.with_file parse
