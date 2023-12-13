module R = MetadataBase.Reader

val read_size : synch_safe:bool -> R.t -> int
val read_size_v2 : R.t -> int
val unterminate : int -> string -> string
val next_substring : int -> ?offset:int -> string -> int
val normalize_id : string -> string
val make_recode : MetadataCharEncoding.recode option -> int -> string -> string

val parse :
  ?bigarray_threshold:int ->
  ?recode:MetadataCharEncoding.recode ->
  R.t ->
  MetadataBase.metadata

val parse_file :
  ?bigarray_threshold:int ->
  ?recode:MetadataCharEncoding.recode ->
  string ->
  MetadataBase.metadata

val dump : R.t -> string
val dump_file : string -> string

type apic = {
  mime : string;
  picture_type : int;
  description : string;
  data : string;
}

type pic = {
  pic_format : string;
  pic_type : int;
  pic_description : string;
  pic_data : string;
}

val parse_apic :
  ?recode:
    (?source:[ `ISO_8859_1 | `UTF_16 | `UTF_16BE | `UTF_16LE | `UTF_8 ] ->
    ?target:[ `UTF_16 | `UTF_16BE | `UTF_16LE | `UTF_8 ] ->
    string ->
    string) ->
  string ->
  apic

val parse_pic :
  ?recode:
    (?source:[ `ISO_8859_1 | `UTF_16 | `UTF_16BE | `UTF_16LE | `UTF_8 ] ->
    ?target:[ `UTF_16 | `UTF_16BE | `UTF_16LE | `UTF_8 ] ->
    string ->
    string) ->
  string ->
  pic

type frame_id =
  [ `AENC
  | `APIC
  | `COMM
  | `COMR
  | `ENCR
  | `EQUA
  | `ETCO
  | `GEOB
  | `GRID
  | `IPLS
  | `LINK
  | `MCDI
  | `MLLT
  | `OWNE
  | `PCNT
  | `POPM
  | `POSS
  | `PRIV
  | `RBUF
  | `RVAD
  | `RVRB
  | `SYLT
  | `SYTC
  | `TALB
  | `TBPM
  | `TCOM
  | `TCON
  | `TCOP
  | `TDAT
  | `TDLY
  | `TENC
  | `TEXT
  | `TFLT
  | `TIME
  | `TIT1
  | `TIT2
  | `TIT3
  | `TKEY
  | `TLAN
  | `TLEN
  | `TMED
  | `TOAL
  | `TOFN
  | `TOLY
  | `TOPE
  | `TORY
  | `TOWN
  | `TPE1
  | `TPE2
  | `TPE3
  | `TPE4
  | `TPOS
  | `TPUB
  | `TRCK
  | `TRDA
  | `TRSN
  | `TRSO
  | `TSIZ
  | `TSRC
  | `TSSE
  | `TXXX
  | `TYER
  | `UFID
  | `USER
  | `USLT
  | `WCOM
  | `WCOP
  | `WOAF
  | `WOAR
  | `WOAS
  | `WORS
  | `WPAY
  | `WPUB
  | `WXXX ]

val string_of_frame_id :
  [< `AENC
  | `APIC
  | `COMM
  | `COMR
  | `ENCR
  | `EQUA
  | `ETCO
  | `GEOB
  | `GRID
  | `IPLS
  | `LINK
  | `MCDI
  | `MLLT
  | `OWNE
  | `PCNT
  | `POPM
  | `POSS
  | `PRIV
  | `RBUF
  | `RVAD
  | `RVRB
  | `SYLT
  | `SYTC
  | `TALB
  | `TBPM
  | `TCOM
  | `TCON
  | `TCOP
  | `TDAT
  | `TDLY
  | `TENC
  | `TEXT
  | `TFLT
  | `TIME
  | `TIT1
  | `TIT2
  | `TIT3
  | `TKEY
  | `TLAN
  | `TLEN
  | `TMED
  | `TOAL
  | `TOFN
  | `TOLY
  | `TOPE
  | `TORY
  | `TOWN
  | `TPE1
  | `TPE2
  | `TPE3
  | `TPE4
  | `TPOS
  | `TPUB
  | `TRCK
  | `TRDA
  | `TRSN
  | `TRSO
  | `TSIZ
  | `TSRC
  | `TSSE
  | `TXXX
  | `TYER
  | `UFID
  | `USER
  | `USLT
  | `WCOM
  | `WCOP
  | `WOAF
  | `WOAR
  | `WOAS
  | `WORS
  | `WPAY
  | `WPUB
  | `WXXX ] ->
  string

type frame_flag =
  [ `File_alter_preservation of bool | `Tag_alter_perservation of bool ]

val default_flags :
  [> `AENC
  | `EQUA
  | `ETCO
  | `MLLT
  | `POSS
  | `RVAD
  | `SYLT
  | `SYTC
  | `TENC
  | `TLEN
  | `TSIZ ] ->
  [> `File_alter_preservation of bool | `Tag_alter_perservation of bool ] list

type text_encoding = [ `ISO_8859_1 | `UTF_16 | `UTF_16BE | `UTF_16LE | `UTF_8 ]
type frame_data = [ `Text of text_encoding * string ]
type frame = { id : frame_id; data : frame_data; flags : frame_flag list }

val write_string : buf:Buffer.t -> string -> unit
val write_int32 : buf:Buffer.t -> int -> unit
val write_int16 : buf:Buffer.t -> int -> unit
val write_int : buf:Buffer.t -> int -> unit
val write_size : buf:Buffer.t -> int -> unit

val render_frame_data :
  version:int ->
  [< `Text of
     [ `ISO_8859_1 | `UTF_16 | `UTF_16BE | `UTF_16LE | `UTF_8 ] * string ] ->
  string

val render_frames : version:int -> frame list -> Buffer.t
val make : version:int -> frame list -> string
