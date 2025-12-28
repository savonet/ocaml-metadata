(* ========================================================================= *)
(* Pure OCaml PDF Metadata Extractor                                        *)
(* Usage: ocaml pdf_meta.ml <filename.pdf>                                  *)
(* ========================================================================= *)

(* exception Error of string *)

(* --- Utility: String & Char Processing --- *)

let is_digit c = c >= '0' && c <= '9'
let is_space c = c = ' ' || c = '\t' || c = '\r' || c = '\n' || c = '\012'

(* Check if string [s] contains substring [sub] starting at [i] *)
let starts_at s sub i =
  let len_s = String.length s in
  let len_sub = String.length sub in
  if i + len_sub > len_s then false
  else
    let rec check j =
      if j = len_sub then true
      else if s.[i + j] <> sub.[j] then false
      else check (j + 1)
    in
    check 0

(* Find last occurrence of substring [sub] in [s] *)
let find_substring_rev s sub =
  let len_s = String.length s in
  let len_sub = String.length sub in
  let rec search i =
    if i < 0 then None
    else if starts_at s sub i then Some i
    else search (i - 1)
  in
  search (len_s - len_sub)

(* Find first occurrence of substring [sub] in [s] starting from [start_pos] *)
let find_substring s sub start_pos =
  let len_s = String.length s in
  let len_sub = String.length sub in
  let rec search i =
    if i > len_s - len_sub then None
    else if starts_at s sub i then Some i
    else search (i + 1)
  in
  search start_pos

(* Read entire file into a string *)
let read_file filename =
  let ic = open_in_bin filename in
  let len = in_channel_length ic in
  let s = really_input_string ic len in
  close_in ic;
  s

(* --- PDF String Decoding --- *)

(* Decode Hex String: <48656C6C6F> -> "Hello" *)
let decode_hex_string content =
  let b = Buffer.create (String.length content / 2) in
  let rec loop i =
    if i >= String.length content then Buffer.contents b
    else
      let c = content.[i] in
      if is_space c then loop (i + 1)
      else if i + 1 < String.length content then
        let hex_pair = String.sub content i 2 in
        try
          let char_code = int_of_string ("0x" ^ hex_pair) in
          Buffer.add_char b (char_of_int char_code);
          loop (i + 2)
        with _ -> loop (i + 1) (* Skip invalid *)
      else loop (i + 1)
  in
  loop 0

(* Decode Literal String: (Hello\nWorld) -> "Hello\nWorld" *)
let decode_literal_string content =
  let b = Buffer.create (String.length content) in
  let len = String.length content in
  let rec loop i =
    if i >= len then Buffer.contents b
    else match content.[i] with
    | '\\' ->
        if i + 1 >= len then (Buffer.add_char b '\\'; Buffer.contents b)
        else
          (match content.[i+1] with
           | 'n' -> Buffer.add_char b '\n'; loop (i + 2)
           | 'r' -> Buffer.add_char b '\r'; loop (i + 2)
           | 't' -> Buffer.add_char b '\t'; loop (i + 2)
           | 'b' -> Buffer.add_char b '\b'; loop (i + 2)
           | 'f' -> Buffer.add_char b '\012'; loop (i + 2)
           | '(' -> Buffer.add_char b '('; loop (i + 2)
           | ')' -> Buffer.add_char b ')'; loop (i + 2)
           | '\\' -> Buffer.add_char b '\\'; loop (i + 2)
           | d when is_digit d -> (* Octal \ddd *)
               let end_oct = min (i + 4) len in
               let oct_str = String.sub content (i + 1) (end_oct - (i + 1)) in
               (* Take up to 3 digits *)
               let oct_len = 
                 let rec count k = 
                   if k < String.length oct_str && is_digit oct_str.[k] then count (k+1) else k 
                 in count 0 
               in
               if oct_len > 0 then
                 let code = int_of_string ("0o" ^ String.sub oct_str 0 oct_len) in
                 Buffer.add_char b (char_of_int code);
                 loop (i + 1 + oct_len)
               else (Buffer.add_char b d; loop (i + 2))
           | c -> Buffer.add_char b c; loop (i + 2))
    | c -> Buffer.add_char b c; loop (i + 1)
  in
  loop 0

(* --- Parsing Logic --- *)

(* Extract the object ID for /Info from the trailer section *)
(* Looks for: /Info 123 0 R *)
let find_info_object_id data =
  (* We search backwards because the valid trailer is usually at the end *)
  match find_substring_rev data "/Info" with
  | None -> None
  | Some idx ->
      let start = idx + 5 in (* Skip "/Info" *)
      let len = String.length data in
      (* Helper to eat whitespace *)
      let rec skip_space i = if i < len && is_space data.[i] then skip_space (i+1) else i in
      (* Helper to read int *)
      let rec read_int i acc =
        if i < len && is_digit data.[i] then 
          read_int (i+1) (acc ^ String.make 1 data.[i])
        else (acc, i)
      in
      let i1 = skip_space start in
      let (obj_id_str, i2) = read_int i1 "" in
      let i3 = skip_space i2 in
      let (gen_id_str, i4) = read_int i3 "" in
      let i5 = skip_space i4 in
      if i5 < len && data.[i5] = 'R' then
        Some (obj_id_str ^ " " ^ gen_id_str)
      else
        None (* Malformed reference *)

(* Locate the content of a specific object: "123 0 obj ... endobj" *)
let get_object_content data obj_id_str =
  let marker = obj_id_str ^ " obj" in
  match find_substring data marker 0 with
  | None -> None
  | Some start_idx ->
      let content_start = start_idx + String.length marker in
      match find_substring data "endobj" content_start with
      | None -> None
      | Some end_idx ->
          Some (String.sub data content_start (end_idx - content_start))

(* Parse the dictionary << /Key (Value) ... >> *)
let parse_dictionary_content content =
  let len = String.length content in
  let result = Hashtbl.create 10 in
  
  let rec skip_whitespace i =
    if i >= len then i
    else if is_space content.[i] then skip_whitespace (i + 1)
    else i
  in

  let rec parse i =
    let i = skip_whitespace i in
    if i >= len then ()
    else if content.[i] = '/' then (* Found a key *)
      let key_start = i + 1 in
      let rec find_key_end k =
        if k >= len || is_space content.[k] || content.[k] = '(' || content.[k] = '<' || content.[k] = '/' || content.[k] = '>'
        then k
        else find_key_end (k + 1)
      in
      let key_end = find_key_end key_start in
      let key = String.sub content key_start (key_end - key_start) in
      
      let val_start = skip_whitespace key_end in
      if val_start >= len then ()
      else
        match content.[val_start] with
        | '(' -> (* Literal String *)
            let rec find_end k depth =
              if k >= len then k
              else match content.[k] with
              | '\\' -> find_end (k + 2) depth (* Skip escaped char *)
              | '(' -> find_end (k + 1) (depth + 1)
              | ')' -> if depth = 0 then k else find_end (k + 1) (depth - 1)
              | _ -> find_end (k + 1) depth
            in
            let val_end = find_end (val_start + 1) 0 in
            let raw_val = String.sub content (val_start + 1) (val_end - (val_start + 1)) in
            Hashtbl.replace result key (decode_literal_string raw_val);
            parse (val_end + 1)
            
        | '<' -> (* Hex String or Dictionary *)
            if val_start + 1 < len && content.[val_start+1] = '<' then 
              parse (val_start + 1) (* Nested dict start, skip for now *)
            else
              let rec find_end k =
                if k >= len then k
                else if content.[k] = '>' then k
                else find_end (k + 1)
              in
              let val_end = find_end (val_start + 1) in
              let raw_val = String.sub content (val_start + 1) (val_end - (val_start + 1)) in
              Hashtbl.replace result key (decode_hex_string raw_val);
              parse (val_end + 1)
        | _ -> (* Other types (numbers, bools), skip to next slash *)
            let rec find_next_slash k =
                if k >= len || content.[k] = '/' || content.[k] = '>' then k
                else find_next_slash (k + 1)
            in
            parse (find_next_slash val_start)
    else
      (* Skip unknown chars usually associated with dictionary start/end delimiters *)
      parse (i + 1)
  in
  parse 0;
  result

(* --- Main Program --- *)

let print_metadata filename =
  try
    Printf.printf "Reading: %s\n" filename;
    let data = read_file filename in
    
    (* 1. Find the Info Object Reference *)
    match find_info_object_id data with
    | None -> Printf.printf "Error: Could not find /Info dictionary in trailer.\n"
    | Some obj_id ->
        Printf.printf "Found Metadata Object: %s\n" obj_id;
        
        (* 2. Get the content of that object *)
        match get_object_content data obj_id with
        | None -> Printf.printf "Error: Could not locate object %s content.\n" obj_id
        | Some content ->
            (* 3. Parse the dictionary *)
            let metadata = parse_dictionary_content content in
            
            Printf.printf "\n--- Metadata ---\n";
            let keys = ["Title"; "Author"; "Subject"; "Keywords"; "Creator"; "Producer"; "CreationDate"; "ModDate"] in
            
            List.iter (fun k ->
              match Hashtbl.find_opt metadata k with
              | Some v -> Printf.printf "%-15s: %s\n" k v
              | None -> ()
            ) keys;
            Printf.printf "----------------\n"
  with
  | Sys_error msg -> Printf.eprintf "File Error: %s\n" msg
  | _ -> Printf.eprintf "An unexpected error occurred.\n"

let () =
  if Array.length Sys.argv < 2 then
    Printf.printf "Usage: %s <pdf_file>\n" Sys.argv.(0)
  else
    print_metadata Sys.argv.(1)
