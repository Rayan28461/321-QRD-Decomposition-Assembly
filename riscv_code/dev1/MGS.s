.data
matrix_A:   # Input Matrix 
	.float 1, 1, 1, 1
	.float 1, 2, 3, 4
	.float 1, 3, 6, 10
	.float 1, 4, 10, 20

result:   # Result Matrix 
    .float 0, 0, 0, 0
    .float 0, 0, 0, 0 
    .float 0, 0, 0, 0
    .float 0, 0, 0, 0


.text
.globl MGS

MGS: 
    # loading the addresses of the data in registers
    la x10, matrix_A            
    la x11, result
    addi x28,x0, 0   # initialize x28 to 0
    add x29, x0, x10 # x29 = x10, a temperory register to store the address of matrix A
    jal x1, length   # finds the length of the matrix and stores it in x28
    addi x5, x0, 0              # k (counter for outer loop)

    Outer:
        addi x6, x5, 1              # j (counter for inner loop)
        fadd.s f0, f0, f0           # initializing f0

        addi x7, x0, 0              # initializing counter
        Normalize: #r_kk = norm(q_k)
            sll x27, x7, x26         # going to x7'th row in Q
            add x27, x5, x27        # go to k'th element in x7'th row
            slli x27, x27, 2        # getting byte address
            add x27, x10, x27       # address of Q[x7][k]
            flw f1, 0(x27)          # f1 = Q[x7][k] = A[x7][k]
            fmul.s f1, f1, f1       
            fadd.s f0, f1, f0       # f0 = r_kk
            addi x7, x7, 1      
            bltu x7, x28, Normalize
            fsqrt.s x0, f0          # f0 = norm(q_k)

        addi x7, x0, 0              # resetting counter
        Update_qk:
            sll x27, x7, x26         # going to x7'th row in Q       
            add x27, x5, x27        # go to k'th element in x7'th row
            slli x27, x27, 2        # getting byte address
            add x27, x10, x27       # address of Q[x7][k]
            flw f1, 0(x27)          # f1 = Q[x7][k]
            fdiv.s f1, f1, f0       
            fsw f1 , 0(x27)
            addi x7, x7, 1      
            bltu x7, x28, Update_qk

        # storing r_kk in R
        sll x27, x5, x26             # going to k'th row in R
        add x27, x5, x27            # go to k'th element in k'th row
        slli x27, x27, 2            # getting byte address
        add x27, x11, x27           # address of R[k][k]
        fsw f0, 0(x27)
        fsub.s f0, f0, f0           # resetting f0 

        beq x6, x28, Exit           # if j = N, exit

        Inner:
            addi x7, x0, 0              # counter for the dot product loop       
            Dot_Product: # r_kj = q_k * q_j
                sll x27, x7, x26         # going to x7'th row in Q
                add x27, x5, x27        # go to k'th element in x7'th row
                slli x27, x27, 2        # getting byte address
                add x27, x10, x27       # address of Q[x7][k]
                flw f1, 0(x27)          # f1 = Q[x7][k]
                sll x27, x7, x26         # going to x7'th row in Q
                add x27, x6, x27        # go to j'th element in x7'th row
                slli x27, x27, 2        # getting byte address
                add x27, x10, x27       # address of Q[x7][j]
                flw f2, 0(x27)          # f2 = Q[x7][j]
                fmul.s f1, f2, f1
                fadd.s f0, f1, f0       # f0 = r_kj
                addi x7, x7, 1          # updating counter
                bltu x7, x28, Dot_Product

            addi x7, x0, 0              # resetting counter       
            Update_qj:  
                sll x27, x7, x26         # going to x7'th row in Q
                add x27, x5, x27        # go to k'th element in x7'th row
                slli x27, x27, 2        # getting byte address
                add x27, x10, x27       # address of Q[x7][k]
                flw f2, 0(x27)          # f2 = Q[x7][k]
                sll x27, x7, x26         # going to x7'th row in Q         
                add x27, x6, x27        # go to j'th element in x7'th row
                slli x27, x27, 2        # getting byte address
                add x27, x10, x27       # address of Q[x7][j]
                flw f1, 0(x27)          # f1 = Q[x7][j]
                fmul.s f2, f0, f2
                fsub.s f1, f1, f2       # calculating q_j = q_j - r_kj * q_k
                fsw f1, 0(x27)          # updating Q[x7][j]
                addi x7, x7, 1          # updating counter
                bltu x7, x28, Update_qj

            # storing r_kj in R
            sll x27, x5, x26             # going to k'th row in R
            add x27, x6, x27            # go to j'th element in k'th row
            slli x27, x27, 2            # getting byte address
            add x27, x11, x27           # address of R[k][j]
            fsw f0, 0(x27)              # storing r_kj in its position
            fsub.s f0, f0, f0           # f0 reset

            addi x6, x6, 1              # incrementing counter j
            bltu x6, x28, Inner         # loop if j < N 

        addi x5, x5, 1          # incrementing counter k
        bltu x5, x28, Outer     # loop if k < N

    Exit:
        addi x10, x0, 10
        ecall

length:
    # assumes that the matrix is a square matrix
    # where n is a power of 2
    # nxn = 2^i x 2^i
    # returns n = x28 = 2^i and i = x26

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
    add x26, x0, x6
    loop3:
        slli x28, x28, 1
        addi x6, x6, -1
        bne x6, x0, loop3

    jalr x0, 0(x1)