module R = MetadataBase.Reader

val parse : R.t -> MetadataBase.metadata

val parse_file :
  ?custom_parser:MetadataBase.custom_parser -> string -> MetadataBase.metadata
