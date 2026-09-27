
(* The type of tokens. *)

type token = 
  | TIMES
  | SET
  | RP
  | PRINT
  | PLUS
  | MINUS
  | LP
  | LET
  | IN
  | IDENT of (string)
  | EQ
  | EOF
  | DIV
  | CST of (int)

(* This exception is raised by the monolithic API functions. *)

exception Error

(* The monolithic API. *)

val prog: (Lexing.lexbuf -> token) -> Lexing.lexbuf -> (Ast.program)
