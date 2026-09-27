	.text
	.globl	main
main:
	pushq %rbp
	movq %rsp, %rbp
	subq $0, %rsp
	pushq $4
	pushq $6
	popq %rbx
	popq %rax
	addq %rbx, %rax
	pushq %rax
	popq %rdi
	call print_int
	pushq $21
	pushq $2
	popq %rbx
	popq %rax
	imulq %rbx, %rax
	pushq %rax
	popq %rdi
	call print_int
	pushq $100
	pushq $2
	popq %rbx
	popq %rax
	cqto
	idivq %rbx
	pushq %rax
	popq %rdi
	call print_int
	pushq $2
	pushq $100
	popq %rbx
	popq %rax
	cqto
	idivq %rbx
	pushq %rax
	popq %rdi
	call print_int
	pushq $3
	pushq $6
	pushq $10
	pushq $5
	popq %rbx
	popq %rax
	cqto
	idivq %rbx
	pushq %rax
	popq %rbx
	popq %rax
	imulq %rbx, %rax
	pushq %rax
	popq %rbx
	popq %rax
	subq %rbx, %rax
	pushq %rax
	popq %rdi
	call print_int
	pushq $0
	pushq $5
	popq %rbx
	popq %rax
	subq %rbx, %rax
	pushq %rax
	pushq $2
	popq %rbx
	popq %rax
	addq %rbx, %rax
	pushq %rax
	popq %rdi
	call print_int
	movq %rbp, %rsp
	popq %rbp
	movq $0, %rax
	ret
print_int:
	pushq %rbp
	movq %rdi, %rsi
	leaq .Sprint_int, %rdi
	movq $0, %rax
	call printf
	popq %rbp
	ret
	.data
.Sprint_int:
	.string "%d\n"
