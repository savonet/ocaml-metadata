module CharEncoding = MetadataCharEncoding

module Make (E : CharEncoding.T) = struct
  include MetadataBase
  module ID3v1 = MetadataID3v1
  module ID3v2 = MetadataID3v2
  module OGG = MetadataOGG
  module FLAC = MetadataFLAC
  module JPEG = MetadataJPEG
  module PNG = MetadataPNG
  module AVI = MetadataAVI
  module MP4 = MetadataMP4

  let recode = E.convert

  module ID3 = struct
    let parse ?max_size f =
      let failure, v2 =
        try (false, ID3v2.parse ~recode ?max_size f) with _ -> (true, [])
      in
      let v1 =
        try
          Reader.reset f;
          ID3v1.parse ~recode ?max_size f
        with _ -> if failure then raise Invalid else []
      in
      v2 @ v1

    let parse_file = Reader.with_file parse
  end

  (** Return the first application which does not raise invalid. *)
  let rec first_valid l ?(max_size : int option) file =
    match l with
      | f :: l -> (
          try f ?max_size file
          with Invalid ->
            Reader.reset file;
            first_valid l file)
      | [] -> raise Invalid

  module Audio = struct
    let parsers = [ID3.parse; OGG.parse; FLAC.parse]
    let parse = first_valid parsers
    let parse_file = Reader.with_file parse
  end

  module Image = struct
    let parsers = [JPEG.parse; PNG.parse]
    let parse = first_valid parsers
    let parse_file = Reader.with_file parse
  end

  module Video = struct
    let parsers = [AVI.parse; MP4.parse]
    let parse = first_valid parsers
    let parse_file = Reader.with_file parse
  end

  module Any = struct
    let parsers = Audio.parsers @ Image.parsers @ Video.parsers
    let parse = first_valid parsers
    let parse_file = Reader.with_file parse
  end

  include Any
end

include Make (CharEncoding.Naive)
