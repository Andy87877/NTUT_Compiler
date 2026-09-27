
exception VarUndef of string
  (** Raised to signal an undeclared variable *)

val compile_program : Ast.program -> string -> unit
  (** [compile_program p f] compiles the program [p] and writes the
      corresponding X86-64 code to the file [f] *)

