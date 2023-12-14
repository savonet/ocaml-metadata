(** Charset conversion. *)

(** Type of functions for converting charset. *)
type recode =
  ?source:[ `ISO_8859_1 | `UTF_8 | `UTF_16 | `UTF_16LE | `UTF_16BE ] ->
  ?target:[ `UTF_8 | `UTF_16 | `UTF_16LE | `UTF_16BE ] ->
  string ->
  string

(** Type of modules for specifying charset conversion. *)
module type T = sig
  (** Convert charset. *)
  val convert : recode
end

(** Basic charset conversion. This module is not complete and we advise the use
    of libraries such as camomile. *)
module Naive : T
