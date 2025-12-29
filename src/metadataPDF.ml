open MetadataBase
module R = Reader

let parse f : metadata =
  if R.read f 5 <> "%PDF-" then raise Invalid;
  let find_slash () = while R.read f 1 <> "/" do () done in
  find_slash ();
  while R.read f 4 <> "Info" do
    find_slash ()
  done;
  assert (R.read f 1 = " ");
  let read_int () =
    let n = ref "" in
    let s = ref @@ R.read f 1 in
    while !s <> " " do
      assert ('0' <= !s.[0] && !s.[0] <= '9');
      n := !n ^ !s;
      s := R.read f 1
    done;
    !n
  in
  let obj_id = read_int () in
  let gen_id = read_int () in
  let marker = obj_id ^ " " ^ gen_id ^ " obj" in
  assert (R.read f 1 = "R");
  R.reset f;
  assert (R.find f marker);
  let obj = R.until f "endobj" in
  Printf.printf "info obj: %s\n%!" obj;
  []

let parse_file ?custom_parser file = R.with_file ?custom_parser parse file
