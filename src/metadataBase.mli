exception Invalid

type metadata = (string * string) list
type endianness = Big_endian | Little_endian

module Reader : sig
  type t = {
    read : bytes -> int -> int -> int;
    seek : int -> unit;
    size : unit -> int option;
    reset : unit -> unit;
  }

  val retry : ('a -> int -> int -> int) -> 'a -> int -> int -> int
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
  val reset : t -> unit
  val with_file : (t -> 'a) -> string -> 'a
  val with_string : (t -> 'a) -> string -> 'a
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
  val seeded_hash : int -> int -> int
  val hash : int -> int
  val find : (int -> bool) -> int
end
