module R = MetadataBase.Reader

val parse : R.t -> MetadataBase.metadata
val parse_file : string -> MetadataBase.metadata

type picture = {
  picture_type : int;
  picture_mime : string;
  picture_description : string;
  picture_width : int;
  picture_height : int;
  picture_bpp : int;
  picture_colors : int;
  picture_data : string;
}

val parse_picture : string -> picture
