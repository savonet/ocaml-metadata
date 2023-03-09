The metadata library
====================

A pure OCaml library to read metadata from various formats. For now, are
supported:

- audio formats: ID3v1 and ID3v2 (for mp3), ogg/vorbis, ogg/opus and flac
- image formats: jpeg and png
- video formats: mp4 and avi

Installing
----------

The preferred way is via opam:

```
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
