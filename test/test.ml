let () =
  assert (Metadata.ID3v2.unterminate 2 "\000ab\000de\000\000" = "\000ab\000de")
