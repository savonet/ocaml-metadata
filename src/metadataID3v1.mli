module R = MetadataBase.Reader

val trim : string -> string
val parse : ?recode:MetadataCharEncoding.recode -> R.t -> MetadataBase.metadata
val parse_file : string -> MetadataBase.metadata
