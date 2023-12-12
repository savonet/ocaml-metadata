module CharEncoding = MetadataCharEncoding

module Make : functor (_ : CharEncoding.T) -> sig
  module Reader = MetadataBase.Reader
  module Int = MetadataBase.Int
  module ID3v1 = MetadataID3v1
  module ID3v2 = MetadataID3v2
  module OGG = MetadataOGG
  module FLAC = MetadataFLAC
  module JPEG = MetadataJPEG
  module PNG = MetadataPNG
  module AVI = MetadataAVI
  module MP4 = MetadataMP4

  exception Invalid

  type endianness = MetadataBase.endianness = Big_endian | Little_endian

  type bigarray =
    (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t

  type value = [ `String of string | `Float of float | `Bigarray of bigarray ]
  type metadata = (string * value) list

  val recode :
    ?source:[ `ISO_8859_1 | `UTF_16 | `UTF_16BE | `UTF_16LE | `UTF_8 ] ->
    ?target:[ `UTF_16 | `UTF_16BE | `UTF_16LE | `UTF_8 ] ->
    string ->
    string

  module ID3 : sig
    val parse : ID3v2.R.t -> (string * value) list
    val parse_file : string -> (string * value) list
  end

  val first_valid : (Reader.t -> 'a) list -> Reader.t -> 'a

  module Audio : sig
    val parsers : (ID3v2.R.t -> MetadataBase.metadata) list
    val parse : Reader.t -> MetadataBase.metadata
    val parse_file : string -> MetadataBase.metadata
  end

  module Image : sig
    val parsers : (JPEG.R.t -> MetadataBase.metadata) list
    val parse : Reader.t -> MetadataBase.metadata
    val parse_file : string -> MetadataBase.metadata
  end

  module Video : sig
    val parsers : (AVI.R.t -> MetadataBase.metadata) list
    val parse : Reader.t -> MetadataBase.metadata
    val parse_file : string -> MetadataBase.metadata
  end

  module Any : sig
    val parsers : (ID3v2.R.t -> MetadataBase.metadata) list
    val parse : Reader.t -> MetadataBase.metadata
    val parse_file : string -> MetadataBase.metadata
  end

  val parsers : (ID3v2.R.t -> MetadataBase.metadata) list
  val parse : Reader.t -> MetadataBase.metadata
  val parse_file : string -> MetadataBase.metadata
end

include module type of Make (CharEncoding.Naive)
