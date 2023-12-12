module R = MetadataBase.Reader

val parse : R.t -> MetadataBase.metadata
val parse_file : string -> MetadataBase.metadata
