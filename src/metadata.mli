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
  type custom_parser =
    ?read_ba:(unit -> bigarray) ->
    read:(unit -> string) ->
    length:int ->
    label:string ->
    unit ->
    unit

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

    val read : t -> int -> string
    val drop : t -> int -> unit
    val byte : t -> int
    val uint8 : t -> int
    val int16_be : t -> int
    val int16_le : t -> int
    val uint16_le : t -> int
    val int16 : endianness -> t -> int
    val int24_be : t -> int
    val int32_le : t -> int
    val uint32_le : t -> int
    val int32_be : t -> int
    val size : t -> int option

    (** Go back at the beginning of the stream. *)
    val reset : t -> unit

    val with_file :
      ?custom_parser:custom_parser -> (t -> metadata) -> string -> metadata

    val with_string :
      ?custom_parser:custom_parser -> (t -> metadata) -> string -> metadata
  end

  module Int : sig
    type t = int

    val zero : int
    val one : int
    val minus_one : int
    external neg : int -> int = "%negint"
    external add : int -> int -> int = "%addint"
    external sub : int -> int -> int = "%subint"
    external mul : int -> int -> int = "%mulint"
    external div : int -> int -> int = "%divint"
    external rem : int -> int -> int = "%modint"
    external succ : int -> int = "%succint"
    external pred : int -> int = "%predint"
    val abs : int -> int
    val max_int : int
    val min_int : int
    external logand : int -> int -> int = "%andint"
    external logor : int -> int -> int = "%orint"
    external logxor : int -> int -> int = "%xorint"
    val lognot : int -> int
    external shift_left : int -> int -> int = "%lslint"
    external shift_right : int -> int -> int = "%asrint"
    external shift_right_logical : int -> int -> int = "%lsrint"
    val equal : int -> int -> bool
    val compare : int -> int -> int
    val min : int -> int -> int
    val max : int -> int -> int
    external to_float : int -> float = "%floatofint"
    external of_float : float -> int = "%intoffloat"
    val to_string : int -> string
    val find : (int -> bool) -> int
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
  end

  val parsers : (Reader.t -> MetadataBase.metadata) list
  val parse : Reader.t -> MetadataBase.metadata

  val parse_file :
    ?custom_parser:custom_parser -> string -> MetadataBase.metadata
end

include module type of Make (CharEncoding.Naive)
