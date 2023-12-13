The metadata library
====================

A pure OCaml library to read metadata from various formats. For now, are
supported:

- audio formats: ID3v1 and ID3v2 (for mp3), ogg/vorbis, ogg/opus and flac
- image formats: jpeg and png
- video formats: mp4 and avi

Usage
-----

Basic usage is

```ocaml
let () =
  let filename = "test.mp3" in
  let metadata = Metadata.Any.parse_file filename in
  List.iter (fun (k,v) -> Printf.printf "- %s: %s\n" k v) metadata
```

In the above example, the function `Metadata.Any.parse_file` takes a file name
as argument and returns an association list describing its metadata. It consists
of pairs of strings being the name of the metadata and its value.

Installing
----------

The preferred way is via opam:

```bash
opam pin add .
opam install metadata
```

It can also be installed via dune:

```
dune install
```

Other libraries
---------------

- [ocaml-taglib](https://github.com/savonet/ocaml-taglib): for tags from audio
  files (mp3, ogg, etc.)
