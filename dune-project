(lang dune 2.8)
(version 0.1.0)
(name metadata)
(source (github savonet/ocaml-metadata))
(license GPL-3.0)
(authors "Samuel Mimram <smimram@gmail.com>")
(maintainers "Samuel Mimram <smimram@gmail.com>")

(generate_opam_files true)

(package
 (name metadata)
 (synopsis "Read metadata from various file formats")
 (description "A pure OCaml library for reading files from various formats.")
 (depends
   (ocaml (>= 4.14.0))
 )
)
