(** Preprocessor for handling include directives *)

open Core_kernel

val location_of_position : Lexing.position -> Middle.Location.t

val location_span_of_positions :
  Lexing.position * Lexing.position -> Middle.Location_span.t

val current_buffer : unit -> Lexing.lexbuf
(** Buffer at the top of the include stack *)

val size : unit -> int
(** Size of the include stack *)

val init : Lexing.lexbuf -> string -> unit
(** Push a buffer on to the stack to start *)

val update_start_positions : Lexing.position -> unit
(** Update the lex_start_p the lexing buffers on the stack.
    This solves an issue where a parser which started with one lexbuf
    but is finishing with another can have the wrong information
*)

val pop_buffer : unit -> Lexing.lexbuf
(** Pop the buffer at the top of the include stack *)

val add_comment : Ast.comment_type -> unit
val get_comments : unit -> Ast.comment_type list

val include_paths : string list ref
(** List of paths to search for including files *)

val included_files : string list ref
(** List of files that have been included *)

val restore_prior_lexbuf : unit -> Lexing.lexbuf
(** Restore to a previous lexing buffer (assumes that one exists) and
    updates positions accordingly. *)

val try_get_new_lexbuf : string -> Lexing.lexbuf
(** Search include paths for filename and try to create a new lexing buffer
    with that filename, record that included from specified position *)
