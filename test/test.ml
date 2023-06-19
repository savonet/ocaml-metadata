let () =
  assert (Metadata.ID3v2.unterminate 2 "\000ab\000de\000\000" = "\000ab\000de");
  (* Little endian. *)
  assert (
    Metadata.CharEncoding.Naive.convert ~source:`UTF_16LE "a\x00b\x00c\x00"
    = "abc");
  assert (
    Metadata.CharEncoding.Naive.convert ~source:`UTF_16
      "\xff\xfea\x00b\x00c\x00"
    = "abc");
  (* Big endian. *)
  assert (
    Metadata.CharEncoding.Naive.convert ~source:`UTF_16BE "\x00a\x00b\x00c"
    = "abc");
  assert (
    Metadata.CharEncoding.Naive.convert ~source:`UTF_16
      "\xfe\xff\x00a\x00b\x00c"
    = "abc")

let () =
  List.iter
    (fun version ->
      let tag =
        Metadata.ID3v2.make ~version
          Metadata.ID3v2.
            [
              {
                id = `TIT2;
                data = `Text (`UTF_8, "foobar😅");
                flags = default_flags `TIT2;
              };
              {
                id = `TALB;
                data = `Text (`UTF_8, "Let's go get them ⚡️");
                flags = [];
              };
            ]
      in
      Metadata.Reader.with_string
        (fun reader ->
          let tags = Metadata.ID3v2.parse reader in
          assert (List.assoc "title" tags = {|foobar😅|});
          assert (List.assoc "album" tags = {|Let's go get them ⚡️|}))
        tag)
    [3; 4]
