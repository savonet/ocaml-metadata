module R = MetadataBase.Reader

val trim : string -> string

val parse :
  ?recode:
    (?source:[ `ISO_8859_1 | `UTF_16 | `UTF_16BE | `UTF_16LE | `UTF_8 ] ->
    ?target:[ `UTF_16 | `UTF_16BE | `UTF_16LE | `UTF_8 ] ->
    string ->
    string) ->
  R.t ->
  MetadataBase.metadata

val parse_file : string -> MetadataBase.metadata
