module R = MetadataBase.Reader

val tagn : (string * string) list
val parse : R.t -> MetadataBase.metadata
val parse_file : string -> MetadataBase.metadata
