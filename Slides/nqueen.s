	.text
	.globl main
t:
	movq	$1, %rax
	testq	%rdi, %rdi
	jz	t_return
	subq	$48, %rsp
	xorq	%rax, %rax
	movq	%rdi, %rcx
	movq	%rsi, %r9
	notq	%r9
	andq	%r9, %rcx
	movq	%rdx, %r9
	notq	%r9
	andq	%r9, %rcx
	jmp	loop_test
loop_body:
	movq	%rdi,  0(%rsp)
	movq	%rsi,  8(%rsp)
	movq	%rdx, 16(%rsp)
	movq	%r8,  24(%rsp)
	movq	%rcx, 32(%rsp)
	movq	%rax, 40(%rsp)
	subq	%r8, %rdi
	addq	%r8, %rsi
	salq	$1, %rsi
	addq	%r8, %rdx
	shrq	$1, %rdx
	call	t
	addq	40(%rsp), %rax
	movq	32(%rsp), %rcx
	subq	24(%rsp), %rcx
	movq	16(%rsp), %rdx
	movq	 8(%rsp), %rsi
	movq	 0(%rsp), %rdi
loop_test:
	movq	%rcx, %r8
	movq	%rcx, %r9
	negq	%r9
	andq	%r9, %r8
	jnz	loop_body
	addq	$48, %rsp
t_return:
	ret
main:
	pushq	%rbp
	movq	%rsp, %rbp
	movq	$input, %rdi
	movq	$n, %rsi
	xorq	%rax, %rax
	call	scanf

	xorq	%rdi, %rdi
	notq	%rdi
	movq	(n), %rcx
	salq	%cl, %rdi
	notq	%rdi
	xorq	%rsi, %rsi
	xorq	%rdx, %rdx
	call	t

	movq	$msg, %rdi
	movq	(n), %rsi
	movq	%rax, %rdx
	xorq	%rax, %rax
	call	printf
	xorq	%rax, %rax
	popq	%rbp
	ret

	.data
n:
	.quad	0
input:
	.string	"%d"
msg:
	.string	"q(%d) = %d\n"	
