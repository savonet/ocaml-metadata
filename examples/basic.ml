(** Basic usage of the library. *)

let () =
  let filename = "test.mp3" in
  let metadata = Metadata.parse_file filename in
  List.iter (fun (k,v) -> Printf.printf "- %s: %s\n" k v) metadata
