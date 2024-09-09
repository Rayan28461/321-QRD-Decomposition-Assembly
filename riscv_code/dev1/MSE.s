.data   
matrix_A:   # Input Matrix 
	.float 1, 1, 1, 1
	.float 1, 2, 3, 4
	.float 1, 3, 6, 10
	.float 1, 4, 10, 20
    
matrix_QR: 
.float 0x3F800000, 0x3F7FFFFF, 0x3F7FFFFF, 0x3F7FFFFD, 
.float 0x3F800000, 0x40000000, 0x40400000, 0x40800000, 
.float 0x3F800000, 0x40400000, 0x40C00000, 0x41200000, 
.float 0x3F800000, 0x40800000, 0x41200000, 0x41A00000,
.text
.globl MSE

MSE: 
    la x10, matrix_A
    la x11, matrix_QR
    addi x28,x0, 0   # initialize x28 to 0
    add x29, x0, x10 # x29 = x11, a temperory register to store the address of matrix A
    jal x1, length   # finds the length of the matrix and stores it in x28
    fadd.s f0, f0, f0       # f0 = sum
    addi x5, x0, 0          # x5 = i

    Outer: addi x6, x0, 0       # x6 = j
        Inner: 
            sll x30, x5,x27         # going to i'th row
            add x30, x30, x6        # going to i'th row and j'th column
            slli x30, x30, 2        # getting byte address
            add x30, x30, x10       # matrix_A[i][j]
            flw f1, 0(x30)          # f1 = matrix_A[i][j]
            sub x30, x30, x10       
            add x30, x30, x11       # matrix_B[i][j]
            flw f2, 0(x30)          # f2 = matrix_B[i][j]

            fsub.s f3, f1, f2       # f3 = matrix_A[i][j] - matrix_B[i][j]
            fmadd.s f0, f3, f3, f0  # f0 = (matrix_A[i][j] - matrix_B[i][j])^2 + f0

            addi x6, x6, 1
            bltu x6, x28, Inner
        
        addi x5, x5, 1
        bltu x5, x28, Outer
    
    fcvt.s.wu f1, x28       # f1 = x28 = n
    fmul.s f1, f1, f1       # f1 = n^2
    fdiv.s f0, f0, f1      # f0 = sum / n^2
    sll x30, x5, x27
    addi x30, x30, 0
    slli x30, x30, 2
    add x30, x30, x11       
    fsw f0, 0(x30)          # store MSE 


Exit:
    addi x10, x0, 10
    ecall

length:
    # assumes that the matrix is a square matrix
    # where n is a power of 2
    # nxn = 2^i x 2^i
    # returns n = x28 = 2^i and i = x27

    # counting the number of elements, x28, in the matrix (lines 80-83)
    loop1: 
        addi x28, x28, 1
        addi x29, x29, 4
        bne  x29, x11, loop1

    # finding x28 = log_4(x28) (lines 87-92)
    # 2^i * 2^i = x28 => 4^i = x28 => i = log_4(x28)
    addi x29, x0, 4     # x29 = 4
    addi x5, x0, 1      # x5 = 1, to compare with x29
    addi x6, x0, 0      # x6 = 0, to store the value of i
    loop2:
        div x28, x28, x29
        addi x6, x6, 1
        bne x28, x5, loop2

    # finding x28 = 2^x28 (lines 97-101)
    # slli x28, x28, 1
    add x27, x0, x6
    loop3:
        slli x28, x28, 1
        addi x6, x6, -1
        bne x6, x0, loop3

    jalr x0, 0(x1)