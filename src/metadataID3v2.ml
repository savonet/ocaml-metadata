open MetadataBase
module R = Reader

let read_size ~synch_safe f =
  let s = R.read f 4 in
  let s0 = int_of_char s.[0] in
  let s1 = int_of_char s.[1] in
  let s2 = int_of_char s.[2] in
  let s3 = int_of_char s.[3] in
  if synch_safe then (
    if s0 lor s1 lor s2 lor s3 land 0b10000000 <> 0 then raise Invalid;
    (s0 lsl 21) + (s1 lsl 14) + (s2 lsl 7) + s3)
  else (s0 lsl 24) + (s1 lsl 16) + (s2 lsl 8) + s3

let read_size_v2 f =
  let s = R.read f 3 in
  let s0 = int_of_char s.[0] in
  let s1 = int_of_char s.[1] in
  let s2 = int_of_char s.[2] in
  (s0 lsl 16) + (s1 lsl 8) + s2

(** Remove trailing nulls. *)
let unterminate encoding s =
  let n = String.length s in
  match encoding with
  | 0 | 3 -> if String.length s > 0 && s.[n-1] = '\000' then String.sub s 0 (n-1) else s
  | 1 | 2 -> if String.length s >= 2 && s.[n-1] = '\000' && s.[n-2] = '\000' then String.sub s 0 (n-2) else s
  | _ -> failwith (Printf.sprintf "Unknown encoding: %d." encoding)

let normalize_id = function
  | "COMM" -> "comment"
  | "TALB" -> "album"
  | "TBPM" -> "tempo"
  | "TCOM" -> "composer"
  | "TCON" -> "content"
  | "TCOP" -> "copyright"
  | "TDAT" -> "date"
  | "TENC" -> "encoder"
  | "TIT2" -> "title"
  | "TLAN" -> "language"
  | "TLEN" -> "length"
  | "TOPE" -> "performer"
  | "TPE1" -> "artist"
  | "TPE2" -> "band"
  | "TPUB" -> "publisher"
  | "TRCK" -> "tracknumber"
  | "TSSE" -> "encoder"
  | "TYER" -> "year"
  | "WXXX" -> "url"
  | id -> id

let make_recode recode =
  let recode = Option.value ~default:(fun ?source:_ s -> s) recode in
  let recode : int -> string -> string = function
    | 0 -> recode ~source:`ISO_8859_1
    | 1 -> (
        fun s ->
          match String.length s with
          (* Probably invalid string *)
          | n when n < 2 -> s
          | n -> (
              match String.sub s 0 2 with
              | "\255\254" | "\255\246" -> recode ~source:`UTF_16LE (String.sub s 2 (n - 2))
              | "\254\255" | "\246\255" -> recode ~source:`UTF_16BE (String.sub s 2 (n - 2))
              (* Probably invalid string *)
              | _ -> recode ~source:`UTF_16 s))
    | 2 -> recode ~source:`UTF_16
    | 3 -> recode ~source:`UTF_8
    (* Invalid encoding. *)
    | _ -> fun s -> s
  in
  fun encoding s -> recode encoding (unterminate encoding s)

(** Parse ID3v2 tags. *)
let parse ?recode f : metadata =
  let recode = make_recode recode in
  let id = R.read f 3 in
  if id <> "ID3" then raise Invalid;
  let version =
    let v1 = R.byte f in
    let v2 = R.byte f in
    [| 2; v1; v2 |]
  in
  let v = version.(1) in
  if not (List.mem v [2; 3; 4]) then raise Invalid;
  let id_len, read_frame_size =
    if v = 2 then (3, read_size_v2) else (4, read_size ~synch_safe:(v > 3))
  in
  let flags = R.byte f in
  let unsynchronization = flags land 0b10000000 <> 0 in
  if unsynchronization then failwith "Unsynchronized headers not handled.";
  let extended_header = flags land 0b1000000 <> 0 in
  let size = read_size ~synch_safe:true f in
  let len = ref size in
  if extended_header then (
    let size = read_size ~synch_safe:(v > 3) f in
    let size = if v = 3 then size else size - 4 in
    len := !len - (size + 4);
    ignore (R.read f size));
  let tags = ref [] in
  while !len > 0 do
    try
      (* We can have 3 null bytes in the end even if id is 4 bytes. *)
      let id_len = min !len id_len in
      let id = R.read f (min !len id_len) in
      if id = "\000\000\000\000" || id = "\000\000\000" then len := 0
      (* stop tag *)
      else
        let size = read_frame_size f in
        (* make sure that we remain within the bounds in case of a problem *)
        let size = min size (!len - 10) in
        let flags = if v = 2 then None else Some (R.read f 2) in
        let data = R.read f size in
        len := !len - (size + 10);
        let compressed =
          match flags with
          | None -> false
          | Some flags -> int_of_char flags.[1] land 0b10000000 <> 0
        in
        let encrypted =
          match flags with
          | None -> false
          | Some flags -> int_of_char flags.[1] land 0b01000000 <> 0
        in
        if compressed || encrypted then raise Exit;
        let len = String.length data in
        if List.mem id ["SEEK"] then ()
        else if id = "TXXX" then
          let encoding = int_of_char data.[0] in
          let data = String.sub data 1 (len - 1) in
          let recode = recode encoding in
          let n =
            let ans = ref 0 in
            try
              for i = 0 to String.length data - (if encoding = 2 || encoding = 3 then 2 else 1) do
                if encoding = 2 || encoding = 3 then
                  if data.[i] = '\000' && data.[i+1] = '\000' then
                    (
                      ans := i + 2;
                      raise Exit
                    )
                  else if data.[i] = '\000' then
                    (
                      ans := i + 1;
                      raise Exit
                    )
              done;
              0
            with
            | Exit -> !ans
          in
          let id, data =
            String.sub data 0 n,
            String.sub data n (String.length data - n)
          in
          let id = recode id in
          let data = recode data in
          tags := (id, data) :: !tags
        else if (id.[0] = 'T' || id = "COMM") && len >= 1 then
          let encoding = int_of_char data.[0] in
          let recode = recode encoding in
          let data = String.sub data 1 (len - 1) |> recode in
          tags := (normalize_id id, data) :: !tags
        else
          tags := (normalize_id id, data) :: !tags
    with Exit -> ()
  done;
  List.rev !tags

let parse_file = R.with_file parse

(** Dump ID3v2 header. *)
let dump f =
  let id = R.read f 3 in
  if id <> "ID3" then raise Invalid;
  let v1 = R.byte f in
  let _v2 = R.byte f in
  if not (List.mem v1 [2; 3; 4]) then raise Invalid;
  let _flags = R.byte f in
  let size = read_size ~synch_safe:true f in
  R.reset f;
  R.read f (10 + size)

let dump_file = R.with_file dump

(** APIC data. *)
type apic = {
  mime : string;
  picture_type : int;
  description : string;
  data : string;
}

type pic = {
  pic_format : string;
  pic_type : int;
  pic_description : string;
  pic_data : string;
}

(** Parse APIC data. *)
let parse_apic ?recode apic =
  let recode = make_recode recode in
  let text_encoding = int_of_char apic.[0] in
  let text_bytes = if text_encoding = 1 || text_encoding = 2 then 2 else 1 in
  let recode = recode text_encoding in
  let n = String.index_from apic 1 '\000' in
  let mime = String.sub apic 1 (n - 1) in
  let n = n + 1 in
  let picture_type = int_of_char apic.[n] in
  let n = n + 1 in
  let l =
    Int.find (fun i ->
        i mod text_bytes = 0
        && apic.[n + i] = '\000'
        && (text_bytes = 1 || apic.[n + i + 1] = '\000'))
  in
  let description = recode (String.sub apic n l) in
  let n = n + l + text_bytes in
  let data = String.sub apic n (String.length apic - n) in
  { mime; picture_type; description; data }

let parse_pic ?recode pic =
  let recode = make_recode recode in
  let text_encoding = int_of_char pic.[0] in
  let text_bytes = if text_encoding = 1 || text_encoding = 2 then 2 else 1 in
  let recode = recode text_encoding in
  let pic_format = String.sub pic 1 3 in
  let pic_type = int_of_char pic.[4] in
  let l =
    Int.find (fun i ->
        i mod text_bytes = 0
        && pic.[5 + i] = '\000'
        && (text_bytes = 1 || pic.[5 + i + 1] = '\000'))
  in
  let pic_description = recode (String.sub pic 5 l) in
  let n = 5 + l + text_bytes in
  let pic_data = String.sub pic n (String.length pic - n) in
  { pic_format; pic_type; pic_description; pic_data }
