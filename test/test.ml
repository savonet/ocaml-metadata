let () =
  assert (Metadata.ID3v2.unterminate 2 "\000ab\000de\000\000" = "\000ab\000de");
  (* Little endian. *)
  assert (Metadata.CharEncoding.Naive.convert ~source:`UTF_16LE "a\x00b\x00c\x00" = "abc");
  assert (Metadata.CharEncoding.Naive.convert ~source:`UTF_16 "\xff\xfea\x00b\x00c\x00" = "abc");
  (* Big endian. *)
  assert (Metadata.CharEncoding.Naive.convert ~source:`UTF_16BE "\x00a\x00b\x00c" = "abc");
  assert (Metadata.CharEncoding.Naive.convert ~source:`UTF_16 "\xfe\xff\x00a\x00b\x00c" = "abc")
