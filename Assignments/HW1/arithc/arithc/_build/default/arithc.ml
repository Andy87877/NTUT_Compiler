
(* main file of arithc compiler*)

open Format
open Lexing

(* compilation option, for stopping after the parser *)
let parse_only = ref false

(* Names of source and target files *)
let ifile = ref ""
let ofile = ref ""

let set_file f s = f := s


(* Options of the compiler displayed when typing arithc --help *)
let options =
  ["-parse-only", Arg.Set parse_only,
   "  For parsing only";
   "-o", Arg.String (set_file ofile),
   "<file>  For specifying the output file name"]

let usage = "usage: arithc [option] file.exp"


(* localize an error by indicating the line and column *)
let localisation pos =
  let l = pos.pos_lnum in
  let c = pos.pos_cnum - pos.pos_bol + 1 in
  eprintf "File \"%s\", line %d, characters %d-%d:\n" !ifile l (c-1) c

let () =
  (* Parsing the command line *)
  Arg.parse options (set_file ifile) usage;

  (* Check that the source file name has been specified *)
  if !ifile="" then begin eprintf "No file to compile\n@?"; exit 1 end;

  (* This file must have the .exp extension *)
  if not (Filename.check_suffix !ifile ".exp") then begin
    eprintf "The input file must have the .exp extension\n@?";
    Arg.usage options usage;
    exit 1
  end;

  (* By default, the target file has the same name as the source file,
     only the extension changes *)
  if !ofile="" then ofile := Filename.chop_suffix !ifile ".exp" ^ ".s";

  (* Open the source file for reading *)
  let f = open_in !ifile in

  (* Create a lexical analysis buffer *)
  let buf = Lexing.from_channel f in

  try
    (* Parsing: the function Parser.prog transforms the lexical buffer into an
       abstract syntax tree if no (lexical or syntactic) error is detected.
       The function Lexer.token is used by Parser.prog to obtain the next token. *)
    let p = Parser.prog Lexer.token buf in
    close_in f;

    (* Stop here if we only want to parse *)
    if !parse_only then exit 0;

    (* Compilation of the abstract syntax tree p. The resulting machine code
       must be written to the target file ofile. *)
    Compile.compile_program p !ofile
  with
    | Lexer.Lexing_error c ->
	(* Lexical error. Get its absolute position and convert it to line number *)
	localisation (Lexing.lexeme_start_p buf);
	eprintf "Error in lexical analysis: %c@." c;
	exit 1
    | Parser.Error ->
	(* Syntax error. Get its absolute position and convert it to line number *)
	localisation (Lexing.lexeme_start_p buf);
	eprintf "Error in syntax analysis@.";
	exit 1
    | Compile.VarUndef s->
	(* Error of variable usage during compilation *)
	eprintf
	  "Compilation error: variable %s is not defined@." s;
	exit 1





