(** Guess the mime-type of a file. *)

let prefixes =
  [
    "ID3", "audio/mpeg";
    "OggS", "audio/ogg";
    "%PDF-", "application/pdf";
    "\137PNG\013\010\026\010", "image/png";
  ]

let of_string s =
  let ans = ref "" in
  try
    List.iter
      (fun (prefix, mime) ->
         if String.starts_with ~prefix s then
           (
             ans := mime;
             raise Exit
           )
      ) prefixes;
    raise Not_found
  with
  | Exit -> !ans

let of_file fname =
  let len = 10 in
  let buf = Bytes.create len in
  let ic = open_in fname in
  let n = input ic buf 0 len in
  let buf = if n = len then buf else Bytes.sub buf 0 n in
  let s = Bytes.unsafe_to_string buf in
  of_string s
