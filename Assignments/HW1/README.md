
# Part A：作業原文

## 337883 Compiler — Compiler Homework 1

### x86-64 Assembly  

115-1

---

# 1 Small x86-64 assembly exercise (50%)

The goal of this assignment is to get some familiarity with x86-64 assembly language, by manually compiling small C programs.

An assembly code is written in a file with suffix `.s` and looks like this:

```asm
.text
.globl main
main:
...
mov $0, %rax # exit code
ret

.data
...
```

You can compile and run such a program as follows:

```bash
gcc -g file.s -o file
./file
```

(Add the option `-no-pie` if you use gcc version 5 or later.)

When needed, you can use `gdb` to execute your program step by step. Use the following commands

```bash
gdb ./file
(gdb) break main
(gdb) run
```

and then execute one step with command `step`.

More information in this tutorial.

This page by Andrew Tolmach provides some information to write/debug x86-64 assembly code. These notes on x86-64 programming are really useful.

---

## 1.1 Printing using printf

### Question 1.1

Compile the following C program:

```c
#include <stdio.h>

int main() {
    printf("n = %d\n", 42);
    return 0;
}
```

To call the library function `printf`, we pass its first argument (the format string) in register `%rdi` and its second argument (here the integer 42) in register `%rsi`, as specified by the calling conventions.

We must also set register `%rax` to zero before calling `printf`, since it is a variadic function (in that case, `%rax` indicates the number of arguments passed in vector registers — here none).

The format string must be declared in the data segment (`.data`) using the directive `.string` that adds a trailing 0-character.

---

## 1.2 Arithmetic expressions

### Question 1.2

Write assembler programs to evaluate and display results of the following arithmetic expressions:

- `4 + 6`
- `21 * 2`
- `4 + 7 / 2`
- `3 - 6 * (10 / 5)`

The expected results are

```text
10
42
7
-9
```

To display an integer, you can use the solution of Exercise 1.1.

---

## 1.3 Boolean expressions

### Question 1.3

Taking the convention that the integer 0 represents the Boolean value false and any other integer represents the value true, write assembly programs to evaluate and display the results of the following expressions (you must display `true` or `false` in the case of a Boolean result):

- `true && false`
- `if 3 <> 4 then 10 * 2 else 14`
- `2 = 3 || 4 <= 2 * 3`

The expected results are

```text
false
20
true
```

It will be useful to write a `print_bool` function to display a boolean.

---

## 1.4 Global variables

### Question 1.4

Write an assembly program that evaluates the following three instructions:

```text
let x = 2
let y = x * x
print (y + x)
```

The variables `x` and `y` will be allocated in the data segment.

The expected outcome is `6`.

---

## 1.5 Local variables

### Question 1.5

Write an assembly program that evaluates the following program:

```text
print (let x = 3 in x * x)

print (let x = 3 in
      (let y = x + x in x * y)
      + (let z = x + 3 in z / z))
```

We will allocate the variables `x`, `y` and `z` in the stack.

The expected result is

```text
9
19
```

---

# 2 Compilation of a mini-language (50%)

The purpose of this exercise is to produce a compiler for a mini-language of arithmetic expressions, called Arith in this followed, towards the x86-64 assembler.

A programming language Arith is composed of a suite of instructions, which are either the introduction of a global variable with the syntax

```text
set <ident> = <expr>
```

or the display of the value of an expression with the syntax

```text
print <expr>
```

Here, `<ident>` denotes a variable name and `<expr>` an arithmetic expression.

Arithmetic expressions can be constructed from integer constants, variables, addition, subtraction, multiplication, division, negation, parentheses, and a `let in` construct introducing a local variable.

More formally, the syntax of arithmetic expressions is thus as follows:

```text
<expr> ::= <integer constant>
         | <ident>
         | ( <expr> )
         | <expr> + <expr>
         | <expr> - <expr>
         | <expr> * <expr>
         | <expr> / <expr>
         | - <expr>
         | let <ident> = <expr> in <expr>
```

Here is an example of a program in the Arith language:

```text
set x = 1 + 2 + 3*4
print (let y = 10 in x + y)
```

Variable names are composed of letters and numbers and cannot begin with a number.

The words `set`, `print`, `let` and `in` are reserved, i.e. they cannot be used as variable names.

Operator precedence is as usual and the `let in` construct has the lowest precedence.

---

## Preamble

To help you build this compiler, we provide its basic structure (as a set of OCaml files `arithc.tar.gz`) that you can download in Teams.

Once this archive is uncompressed with

```bash
tar zxvf arithc.tar.gz
```

you get an `arithc/` directory containing the following files:

```text
ast.ml                  arbitrary syntax of Arith (completed)
lexer.mll               lexical analyzer (completed)
parser.mly              parser (completed)
x86_64.mli, x86_64.ml   for writing x86-64 code (completed)
compile.ml              the compilation itself (to be completed)
arithc.ml               the main program (completed)
Makefile/dune            to automate compilation (completed)
```

The provided code compiles (type `make`, which will launch a build) but it is incomplete: the assembly code produced is empty.

You must complete the `compile.ml` file.

The program expects an Arith file with the suffix `.exp`.

When you do `make`, the program is launched on the `test.exp` file, which has the effect of producing a `test.s` file containing the assembly code, then the commands

```bash
gcc -g -no-pie test.s -o test.out
./test.out
```

are launched.

To debug, we can examine the content of `test.s` and if necessary use a debugger like `gdb` with the command

```bash
gdb ./test.out
```

then the step-by-step mode with `step`.

### Note to macOS users

You must modify the line

```ocaml
let mangle = mangle_none
```

in the provided `x86_64.ml` file, to replace it with

```ocaml
let mangle = mangle_leading_underscore
```

You must also replace

```ocaml
let lab = abslab
```

with

```ocaml
let lab = rellab
```

---

## Scheme of compilation

We will carry out a simple compilation using the stack to store intermediate values (i.e. the values of subexpressions).

Remember that an integer value takes up 8 bytes in memory.

We can allocate 8 bytes on the stack by subtracting 8 from the value of `%rsp` or by using the `pushq` instruction.

Global variables will be allocated in the data segment (assembler `.data` directive; here it corresponds to the `data` field of type `X86_64.program`).

Local variables will be allocated on the stack.

The space needed for all local variables will be allocated at program startup (by an appropriate subtraction on `%rsp`), after saving `%rbp`.

The `%rbp` register will be positioned so as to point to the top of the space reserved for local variables.

```text
        +-------------+
        | adr. retour |
        +-------------+
        | ancien %rbp |
%rbp -> +-------------+ ^
        | var. locale | |
        | var. locale | | frame_size (multiple de 16)
        | ...         | |
%rsp -> +-------------+ v
```

So any reference to a local variable will be relative to `%rbp`, with an offset of `-8`, `-16`, etc., depending on the variable.

**Warning:** before calling a library function like `printf`, the stack must be aligned to 16 bytes.

Once the value of `frame_size` is determined, we therefore ensure that it is a multiple of 16 (see the code provided).

---

## Exercises to do

You have to read carefully the code in `compile.ml`.

The parts to be completed, marked

```ocaml
(* to be completed *)
```

are the following:

### 1

The `compile_expr` function that compiles an arithmetic expression `e` into a sequence of x86-64 instructions whose effect is to place the value of `e` on the top of the stack.

This function is defined using a local recursive function `comprec` that takes as arguments:

- a parameter `env` of type `StrMap.t`: it is a dictionary indicating for each local variable its position on the stack (relative to `%rbp`);
- a parameter `next` of type `int`: indicates the first free location for a local variable (relative to `%rbp`);
- the expression to compile, on which a pattern matching is performed.

### 2

The `compile_instr` function that compiles an Arith instruction into a sequence of x86-64 instructions.

In both cases (`set x = e` or `print e`), we must start by compiling `e`, then we find the value of `e` on the top of the stack (do not forget to pop).

### 3

The `compile_program` function that applies `compile_instr` to all the instructions of the program and adds code:

- before, in particular to allocate space for local variables and set `%rbp`;
- after, to restore the stack and terminate the program with `ret`.

### Indications

We can proceed construction by construction, testing each time, in the following order:

1. constant expression `Cst`, instruction `Print` and exit with `ret`;
2. arithmetic operations (`Binop` constructor);
3. global variables (`Var` and `Set` constructors);
4. local variables (`Letin` and `Var` constructors).

We will finally test with the `test.exp` file (also provided), the result of which should be as follows:

```text
60
50
0
10
55
60
20
43
```

---

## Optional question

To use a little less stack space, we can improve this compilation scheme a bit so that the result of `compile_expr` ends up in the `%rax` register rather than on top of the stack.

In this way, only the results of left-hand side subexpressions end up on the stack.

---

# Part B：繁體中文翻譯

## 337883 編譯器 — 編譯器作業 1

### x86-64 組合語言  

115-1

---

# 1 小型 x86-64 組合語言練習（50%）

本作業的目標，是透過手動編譯一些小型 C 程式，讓你熟悉 x86-64 組合語言。

組合語言程式會寫在副檔名為 `.s` 的檔案中，其形式如下：

```asm
.text
.globl main
main:
...
mov $0, %rax # 結束代碼
ret

.data
...
```

你可以使用以下方式編譯並執行這類程式：

```bash
gcc -g file.s -o file
./file
```

如果你使用 gcc 5 或更新版本，請加入 `-no-pie` 選項。

有需要時，可以使用 `gdb` 逐步執行程式。使用以下指令：

```bash
gdb ./file
(gdb) break main
(gdb) run
```

之後可以使用 `step` 指令一次執行一個步驟。

更多資訊可以參考此教學。

Andrew Tolmach 的這個頁面提供了一些撰寫及除錯 x86-64 組合語言程式的資訊。這些 x86-64 程式設計筆記也非常實用。

---

## 1.1 使用 printf 輸出

### 問題 1.1

將下列 C 程式編譯成組合語言：

```c
#include <stdio.h>

int main() {
    printf("n = %d\n", 42);
    return 0;
}
```

若要呼叫函式庫函式 `printf`，依照函式呼叫慣例，我們將第一個參數（格式字串）放在 `%rdi` 暫存器中，第二個參數（此處為整數 42）放在 `%rsi` 暫存器中。

在呼叫 `printf` 之前，也必須將 `%rax` 暫存器設定為 0，因為 `printf` 是一個可變參數函式（variadic function）。在這種情況下，`%rax` 表示有多少參數透過向量暫存器傳遞；此處沒有任何這類參數。

格式字串必須使用 `.string` 指令宣告在資料區段 `.data` 中。`.string` 會自動在字串結尾加入一個值為 0 的字元。

---

## 1.2 算術運算式

### 問題 1.2

撰寫組合語言程式，計算並顯示以下算術運算式的結果：

- `4 + 6`
- `21 * 2`
- `4 + 7 / 2`
- `3 - 6 * (10 / 5)`

預期結果如下：

```text
10
42
7
-9
```

若要顯示一個整數，可以使用練習 1.1 的解法。

---

## 1.3 布林運算式

### 問題 1.3

採用以下慣例：

- 整數 `0` 表示布林值 `false`
- 任何非 `0` 的整數表示布林值 `true`

請撰寫組合語言程式，計算並顯示以下運算式的結果。

若結果是布林值，必須顯示 `true` 或 `false`：

- `true && false`
- `if 3 <> 4 then 10 * 2 else 14`
- `2 = 3 || 4 <= 2 * 3`

預期結果如下：

```text
false
20
true
```

撰寫一個 `print_bool` 函式來顯示布林值會很有幫助。

---

## 1.4 全域變數

### 問題 1.4

撰寫一個組合語言程式，執行以下三個指令：

```text
let x = 2
let y = x * x
print (y + x)
```

變數 `x` 與 `y` 將配置在資料區段（data segment）中。

預期結果為：

```text
6
```

---

## 1.5 區域變數

### 問題 1.5

撰寫一個組合語言程式，執行以下程式：

```text
print (let x = 3 in x * x)

print (let x = 3 in
      (let y = x + x in x * y)
      + (let z = x + 3 in z / z))
```

我們會將變數 `x`、`y` 和 `z` 配置在堆疊（stack）中。

預期結果如下：

```text
9
19
```

---

# 2 小型語言的編譯（50%）

本練習的目的是製作一個編譯器，將一個用於算術運算式的小型語言編譯成 x86-64 組合語言。

以下將這個小型語言稱為 **Arith**。

Arith 程式語言由一連串指令所組成。這些指令可以是建立一個全域變數，其語法為：

```text
set <ident> = <expr>
```

或者顯示某個運算式的值，其語法為：

```text
print <expr>
```

其中：

- `<ident>` 表示變數名稱。
- `<expr>` 表示算術運算式。

算術運算式可以由下列項目組成：

- 整數常數
- 變數
- 加法
- 減法
- 乘法
- 除法
- 負號運算
- 括號
- `let in` 結構，用來建立區域變數

更正式地說，算術運算式的語法如下：

```text
<expr> ::= <integer constant>
         | <ident>
         | ( <expr> )
         | <expr> + <expr>
         | <expr> - <expr>
         | <expr> * <expr>
         | <expr> / <expr>
         | - <expr>
         | let <ident> = <expr> in <expr>
```

以下是一個 Arith 語言程式的範例：

```text
set x = 1 + 2 + 3*4
print (let y = 10 in x + y)
```

變數名稱由英文字母和數字組成，而且不能以數字開頭。

以下單字是保留字：

```text
set
print
let
in
```

也就是說，它們不能被拿來當作變數名稱。

運算子的優先順序與一般情況相同，而 `let in` 結構具有最低的優先順序。

---

## 前置說明

為了協助你建立這個編譯器，我們提供了它的基本架構。

這些程式碼是一組 OCaml 檔案，放在 `arithc.tar.gz` 中，可以從 Teams 下載。

使用以下指令解壓縮：

```bash
tar zxvf arithc.tar.gz
```

解壓縮之後，會得到一個 `arithc/` 目錄，其中包含以下檔案：

```text
ast.ml                  Arith 的 arbitrary syntax（已完成）
lexer.mll               詞彙分析器（已完成）
parser.mly              語法分析器（已完成）
x86_64.mli, x86_64.ml   用來產生 x86-64 程式碼（已完成）
compile.ml              編譯本身的實作（需要完成）
arithc.ml               主程式（已完成）
Makefile/dune            自動化編譯（已完成）
```

老師提供的程式碼本身可以成功編譯。

輸入：

```bash
make
```

即可啟動建置程序。

但是目前提供的程式碼仍然是不完整的：它所產生的組合語言程式碼是空的。

你必須完成：

```text
compile.ml
```

這個檔案。

程式預期接收一個副檔名為 `.exp` 的 Arith 程式檔。

執行：

```bash
make
```

時，程式會對 `test.exp` 執行編譯。

執行後會產生：

```text
test.s
```

其中包含產生出的組合語言程式碼。

接著會執行：

```bash
gcc -g -no-pie test.s -o test.out
./test.out
```

若需要除錯，可以檢查 `test.s` 的內容。

必要時也可以使用 `gdb` 除錯器：

```bash
gdb ./test.out
```

然後使用：

```text
step
```

進行逐步執行。

### macOS 使用者注意事項

你必須修改提供的 `x86_64.ml` 檔案。

將：

```ocaml
let mangle = mangle_none
```

改成：

```ocaml
let mangle = mangle_leading_underscore
```

同時也必須將：

```ocaml
let lab = abslab
```

改成：

```ocaml
let lab = rellab
```

---

## 編譯方案

我們將使用一種簡單的編譯方式，使用堆疊（stack）來儲存中間結果，也就是子運算式的計算結果。

請記住：

一個整數值在記憶體中占用：

```text
8 bytes
```

我們可以透過將 `%rsp` 的值減少 8，或者使用 `pushq` 指令，在堆疊上配置 8 bytes 的空間。

全域變數會配置在資料區段中。

在組合語言中，就是：

```asm
.data
```

在這裡則對應到 `X86_64.program` 型別中的 `data` 欄位。

區域變數則會配置在堆疊中。

所有區域變數所需要的空間，都會在程式啟動時一次配置。

具體作法是在保存 `%rbp` 之後，適當地減少 `%rsp` 的值。

`%rbp` 暫存器會被設定成指向為區域變數保留之空間的頂端。

```text
        +-------------+
        | 返回位址    |
        +-------------+
        | 舊的 %rbp   |
%rbp -> +-------------+ ^
        | 區域變數    | |
        | 區域變數    | | frame_size（16 的倍數）
        | ...         | |
%rsp -> +-------------+ v
```

因此，任何對區域變數的存取，都會使用相對於 `%rbp` 的位置。

依照變數不同，其 offset 可能是：

```text
-8
-16
...
```

### 警告

在呼叫像 `printf` 這類函式庫函式之前，stack 必須按照 **16 bytes 對齊**。

因此，一旦決定 `frame_size` 的值之後，我們必須確保它是：

```text
16 的倍數
```

請參考提供的程式碼。

---

## 需要完成的練習

你必須仔細閱讀：

```text
compile.ml
```

中的程式碼。

需要完成的部分都會標記：

```ocaml
(* to be completed *)
```

需要完成的部分如下。

---

### 1. `compile_expr` 函式

`compile_expr` 函式負責將一個算術運算式 `e` 編譯成一連串 x86-64 指令。

執行這些指令之後，運算式 `e` 的值必須位於：

```text
stack 的最上方
```

此函式使用一個區域遞迴函式 `comprec` 來定義。

`comprec` 接收以下參數：

- 一個型別為 `StrMap.t` 的 `env` 參數：它是一個字典，用來記錄每一個區域變數在 stack 上的位置，也就是相對於 `%rbp` 的位置。
- 一個型別為 `int` 的 `next` 參數：它表示下一個可供區域變數使用的位置，同樣是相對於 `%rbp` 的位置。
- 要編譯的運算式，程式會對這個運算式進行 pattern matching。

---

### 2. `compile_instr` 函式

`compile_instr` 函式負責將一個 Arith 指令編譯成一連串 x86-64 指令。

無論是哪一種情況：

```text
set x = e
```

或：

```text
print e
```

我們都必須先編譯：

```text
e
```

接著，`e` 的值會位於 stack 的最上方。

**不要忘記使用 pop 將它取出。**

---

### 3. `compile_program` 函式

`compile_program` 函式會對程式中的所有指令套用：

```text
compile_instr
```

並且額外加入一些程式碼。

在程式開始之前，特別需要：

- 為區域變數配置空間。
- 設定 `%rbp`。

在程式執行完成之後，需要：

- 恢復 stack。
- 使用 `ret` 結束程式。

---

## 提示

我們可以一個結構、一個結構逐步完成。

每完成一個部分就進行測試。

建議按照以下順序：

1. 常數運算式 `Cst`、`Print` 指令，以及使用 `ret` 結束程式。
2. 算術運算，也就是 `Binop` constructor。
3. 全域變數，也就是 `Var` 與 `Set` constructors。
4. 區域變數，也就是 `Letin` 與 `Var` constructors。

最後，我們會使用同樣有提供的：

```text
test.exp
```

檔案進行測試。

正確結果應該為：

```text
60
50
0
10
55
60
20
43
```

---

## 選做題

為了減少 stack 空間的使用量，我們可以稍微改善目前的編譯方式。

讓：

```text
compile_expr
```

的執行結果不再放在 stack 最上方，而是放在：

```text
%rax
```

暫存器中。

如此一來，只有左側子運算式的計算結果需要放入 stack 中。
