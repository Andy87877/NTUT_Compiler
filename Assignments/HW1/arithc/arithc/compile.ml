

(* Code production for the language Arith *)

open Format
open X86_64
open Ast


(* Raise exception when a variable (local or global) is misused *)
exception VarUndef of string

(* Size of the frame, in bytes (each local variable occupies 8 bytes) *)
let frame_size = ref 0

(* Global variables are stored in a hash table *)
let (genv : (string, unit) Hashtbl.t) = Hashtbl.create 17

(* We use an association table whose keys are local variables
   (strings) and whose associated value is the position
   relative to %rbp (in bytes) *)
module StrMap = Map.Make(String)


(* Compilation of an expression *)
let compile_expr =
  (* Recursive local function to generate the machine code
     for the abstract syntax tree associated with a value of type
     Ast.expr ; at the end of the execution of this code, the value must be
     on top of the stack *)
  let rec comprec env next = function
    | Cst i ->
        pushq (imm i)
    | Var x ->
        begin try
          let ofs = StrMap.find x env in
          pushq (ind ~ofs rbp)
        with Not_found ->
          if Hashtbl.mem genv x then
            pushq (lab x)
          else
            raise (VarUndef x)
        end
    | Binop (o, e1, e2) ->
        let op = match o with
          | Add -> addq !%rbx !%rax
          | Sub -> subq !%rbx !%rax
          | Mul -> imulq !%rbx !%rax
          | Div -> cqto ++ idivq !%rbx
        in
        comprec env next e1 ++
        comprec env next e2 ++
        popq rbx ++
        popq rax ++
        op ++
        pushq !%rax
    | Letin (x, e1, e2) ->
        if !frame_size = next then frame_size := 8 + !frame_size;
        nop (* to be completed *)
  in
  comprec StrMap.empty 0

(* Compilation of an instruction *)
let compile_instr = function
  | Set (x, e) ->
      let c = compile_expr e in
      Hashtbl.replace genv x ();
      c ++ popq rax ++ movq !%rax (lab x)
  | Print e ->
      compile_expr e ++
      popq rdi ++
      call "print_int"


(* Compilation of the program p and saving the code in the file ofile *)
let compile_program p ofile =
  let code = List.map compile_instr p in
  let code = List.fold_right (++) code nop in
  if !frame_size mod 16 = 8 then frame_size := 8 + !frame_size;
  let p =
    { text =
        globl "main" ++ label "main" ++
        pushq !%rbp ++
        movq !%rsp !%rbp ++
        subq (imm !frame_size) !%rsp ++
        code ++
        movq !%rbp !%rsp ++
        popq rbp ++
        movq (imm 0) !%rax ++
        ret ++
        label "print_int" ++
        pushq !%rbp ++ (* ensure proper alignment *)
        movq !%rdi !%rsi ++
        leaq (lab ".Sprint_int") rdi ++
        movq (imm 0) !%rax ++
        call "printf" ++
        popq rbp ++
        ret;
      data =
        Hashtbl.fold (fun x _ l -> label x ++ dquad [1] ++ l) genv
          (label ".Sprint_int" ++ string "%d\n")
    }
  in
  let f = open_out ofile in
  let fmt = formatter_of_out_channel f in
  X86_64.print_program fmt p;
  (* flush the buffer to ensure everything is written before closing *)
  fprintf fmt "@?";
  close_out f
