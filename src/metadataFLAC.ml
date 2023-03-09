open MetadataBase
module R = Reader

let parse f : metadata =
  let id = R.read f 4 in
  if id <> "fLaC" then raise Invalid;
  let tags = ref [] in
  let rec block () =
    let n = R.uint8 f in
    let last = n land 0b10000000 <> 0 in
    let block_type = n land 0b01111111 in
    let len = R.int24_be f in
    (
      match block_type with
      | 4 ->
        (* Vorbis comment *)
        let n = ref 0 in
        let vendor_len = R.uint32_le f in
        let vendor = R.read f vendor_len in
        n := !n + 4 + vendor_len;
        tags := ("vendor", vendor) :: !tags;
        let list_len = R.uint32_le f in
        n := !n + 4;
        for _ = 1 to list_len do
          let len = R.uint32_le f in
          let tag = R.read f len in
          n := !n + 4 + len;
          match String.index_opt tag '=' with
          | Some k ->
            let field = String.sub tag 0 k |> String.lowercase_ascii in
            let value = String.sub tag (k+1) (len-(k+1)) in
            tags := (field, value) :: !tags
          | None -> ()
        done;
        R.drop f (len - !n)
      | 6 ->
        let picture = R.read f len in
        tags := ("picture", picture) :: !tags
      | _ -> R.drop f len
    );
    if not last then block ()
  in
  block ();
  List.rev !tags

let parse_file = R.with_file parse
