module R = MetadataBase.Reader

val tagn : (string * string) list
val parse : R.t -> MetadataBase.metadata

val parse_file :
  ?custom_parser:MetadataBase.custom_parser -> string -> MetadataBase.metadata
