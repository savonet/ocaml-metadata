module CharEncoding = MetadataCharEncoding

module Make : functor (_ : CharEncoding.T) -> sig
  exception Invalid

  type endianness = MetadataBase.endianness
  type metadata = (string * string) list

  type bigarray =
    (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t

  (** When used, a custom parser can override the default parsing mechanism.
      It is passed the metadata label (without normalization), the expected
      length of the data, a regular read function an an optional bigarray read
      function. The custom parser can call any of the read function to get the
      corresponding tag's value. After doing so, the tag is ignored by the regular
      parsing process. 

      Currently only supported for: ID3v2, MP4 and [metadata_block_picture] in
      FLAC metadata. *)
  type parser_handler = MetadataBase.parser_handler = {
    label : string;
    length : int;
    read : unit -> string;
    read_ba : (unit -> bigarray) option;
    skip : unit -> unit;
  }

  type custom_parser = parser_handler -> unit

  module Reader : sig
    (** A function to read taking the buffer to fill the offset and the length and
      returning the number of bytes actually read. *)
    type t = MetadataBase.Reader.t = {
      read : bytes -> int -> int -> int;
      read_ba : (int -> MetadataBase.bigarray) option;
      custom_parser : custom_parser option;
      seek : int -> unit;
      size : unit -> int option;
      reset : unit -> unit;
    }

    (** Go back at the beginning of the stream. *)
    val reset : t -> unit

    val with_file :
      ?custom_parser:custom_parser -> (t -> metadata) -> string -> metadata

    val with_string :
      ?custom_parser:custom_parser -> (t -> metadata) -> string -> metadata
  end

  module ID3v1 = MetadataID3v1
  module ID3v2 = MetadataID3v2
  module OGG = MetadataOGG
  module FLAC = MetadataFLAC
  module JPEG = MetadataJPEG
  module PNG = MetadataPNG
  module AVI = MetadataAVI
  module MP4 = MetadataMP4

  val recode :
    ?source:[ `ISO_8859_1 | `UTF_16 | `UTF_16BE | `UTF_16LE | `UTF_8 ] ->
    ?target:[ `UTF_16 | `UTF_16BE | `UTF_16LE | `UTF_8 ] ->
    string ->
    string

  module ID3 : sig
    val parse : Reader.t -> (string * string) list

    val parse_file :
      ?custom_parser:custom_parser -> string -> (string * string) list
  end

  (** Return the first application which does not raise invalid. *)
  val first_valid : (Reader.t -> metadata) list -> Reader.t -> metadata

  module Audio : sig
    val parsers : (Reader.t -> MetadataBase.metadata) list
    val parse : Reader.t -> MetadataBase.metadata

    val parse_file :
      ?custom_parser:custom_parser -> string -> MetadataBase.metadata
  end

  module Image : sig
    val parsers : (Reader.t -> MetadataBase.metadata) list
    val parse : Reader.t -> MetadataBase.metadata

    val parse_file :
      ?custom_parser:custom_parser -> string -> MetadataBase.metadata
  end

  module Video : sig
    val parsers : (Reader.t -> MetadataBase.metadata) list
    val parse : Reader.t -> MetadataBase.metadata

    val parse_file :
      ?custom_parser:custom_parser -> string -> MetadataBase.metadata
  end

  module Any : sig
    val parsers : (Reader.t -> MetadataBase.metadata) list
    val parse : Reader.t -> MetadataBase.metadata

    val parse_file :
      ?custom_parser:custom_parser -> string -> MetadataBase.metadata

    val parse_string :
      ?custom_parser:custom_parser -> string -> MetadataBase.metadata
  end

  include module type of Any
end

include module type of Make (CharEncoding.Naive)
