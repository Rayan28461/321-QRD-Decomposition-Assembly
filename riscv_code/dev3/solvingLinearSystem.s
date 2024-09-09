.data
    matrix_A: # nxn matrix
        .float 1,  1,  1,  1
        .float 2, -3,  4, -5
        .float 3,  2,  0, -1
        .float -1, 4, -2,  3
    matrix_R: # matrix R of the QR decomposition
        .float 0,0,0,0
        .float 0,0,0,0
        .float 0,0,0,0
        .float 0,0,0,0
    vector_b: # Ax = b
        .float 10, 20, 15, 5

    vector_x: # solution of the system
        .float 0,0,0,0

.text
.globl Solve

Solve:
    la x10, matrix_A
    la x11, matrix_R
    la x12, vector_b
    la x13, vector_x
    addi x28, x0, 4     # x28 = n = length of vector_b

    # call MGS subroutine to get Q and R
    jal x1, MGS

    # calling Transpose subroutine to transpose Q
    jal x1, Tranpose

    # updating b; b = Q' * b (lines 35 - 53)
    # load vector_b onto stack
    addi x14, x0, 0     # counter for the loop
    loop: 
        slli x27, x14, 2        # going to x14'th element in vector_b
        add x27, x12, x27       # &vector_b[x14]
        flw f0, 0(x27)          # f0 = vector_b[x14]
        sub sp, sp, x28         # decrementing stack pointer
        fsw f0, 0(sp)           # pushing vector_b[x14] onto stack
        addi x14, x14, 1        # incrementing counter
        bltu x14, x28, loop     # loop if counter < n

    # calling matrix multiplication subroutine to calculate Q' * b
    jal x1, mm

    # unload the stack (the values in the stack are not needed anymore)
    addi x14, x0, 4     # x14 = 4 because each element is 4 Bytes
    mul x14, x28, x14
    add sp, sp, x14

    # calculating x_i's (via BACKWARD SUBSTITUTION) and storing them in vector_x (lines 55 - 89)
    # calculating vector_x[n-1] = b[n-1]/R[n-1][n-1] (lines 56 - 68)
    addi x14, x0, 3     # x14 = n-1
    slli x29, x14, 2    # byte address of n-1'th element in vector_b
    add x29, x12, x29   # &b[n-1]
    flw f0, 0(x29)      # f0 = b[n-1]
    slli x29, x14, 2    # going to n-1'th row in R
    add x29, x14, x29   # going to n-1'th element in n-1'th row
    slli x29, x29, 2    # getting byte address
    add x29, x11, x29   # &R[n-1][n-1]
    flw f1, 0(x29)      # f1 = R[n-1][n-1]
    slli x29, x14, 2    # byte address of n-1'th element in vector_x
    add x29, x13, x29   # &x[n-1]
    fdiv.s f0, f0, f1   # f0 = b[n-1]/R[n-1][n-1]
    fsw f0, 0(x29)      # storing b[n-1]/R[n-1][n-1] in x[n-1]

    # calculating vector_x[i] for i = 0 to n-2 (lines 71 - 89)
    addi x14, x28, -2     # x14 = i = n-2, counter for calc_x
    calc_x:
        fsub.s f0, f0, f0       # resetting f0
        jal x1, Dot_Product1    # calling dot product subroutine
        slli x29, x14, 2        # byte address of i'th element in vector_b
        add x29, x12, x29       # &b[i]
        flw f1, 0(x29)          # f1 = b[i]
        slli x29, x14, 2        # going to i'th row in R
        add x29, x14, x29       # go to i'th element in i'th row
        slli x29, x29, 2        # getting byte address
        add x29, x11, x29       # &R[i][i]
        flw f2, 0(x29)          # f2 = R[i][i]
        slli x29, x14, 2        # byte address of i'th element in vector_x
        add x29, x13, x29       # &vector_x[i]
        fsub.s f1, f1, f0       # f1 = b[i] - R[i][i+1:n] * x[i+1:n]
        fdiv.s f1, f1, f2       # f1 = (b[i] - R[i][i+1:n] * x[i+1:n]) / R[i][i]
        fsw f1, 0(x29)          # storing (b[i] - R[i][i+1:n] * x[i+1:n]) / R[i][i] in x[i]
        addi x14, x14, -1       # decrementing counter
        bge x14, x0, calc_x    # loop if i >= 0

Exit:
    addi x10, x0, 10
    ecall

Dot_Product1: # R(i, i+1 : n) * x(i+1:n,1)
    addi x7, x14, 1        # j = i+1, counter for loop1
    loop1:
        slli x27, x14, 2        # going to i'th row in R
        add x27, x7, x27        # go to j'th element in i'th row
        slli x27, x27, 2        # getting byte address
        add x27, x11, x27       # &R[i][j]
        flw f1, 0(x27)          # f1 = R[i][j]
        slli x27, x7, 2         # going to j'th element in vector_x
        add x27, x13, x27       # &vector_x[j]
        flw f2, 0(x27)          # f2 = vector_x[j]
        fmul.s f1, f2, f1
        fadd.s f0, f1, f0       # f0 = r_kj
        addi x7, x7, 1          # updating counter 
        bltu x7, x28, loop1     # loop if j < n 
    jalr x0, 0(x1)

mm:
    # updated to multiply a matrix with a column vector
    addi x6,x0,0        # j (counter for middle loop)
    Loop1: 
        addi x7,x0,0        # k (counter for inner loop)
        slli x30, x6, 2     # going to i'th element in vector_b
        add x30, x12, x30   # &b[i]
        fsub.s f0, f0, f0   # f0 = 0
        Loop2: 
            addi x29, x0, 3     # x29 = 3 = n-1
            sub x29, x29, x7    # x29 = n-1-k
            slli x29, x29, 2    # byte address
            add x29, x29, sp    # &sp[n-1-k] 
            flw f1, 0(x29)      # f1 = sp[n-1-k]
            slli x29, x6, 2 
            add x29, x29, x7 
            slli x29, x29, 2 
            add x29, x10, x29 
            flw f2, 0(x29)      # f2 = Q'[i][k]
            fmul.s f1, f2, f1
            fadd.s f0, f0, f1
            addi x7, x7, 1
            bltu x7, x28, Loop2 
            fsw f0, 0(x30)
            addi x6, x6, 1 
            bltu x6, x28, Loop1
    
    jalr x0, 0(x1)

MGS: 
    addi x28, x0, 4             # x28 = size of the matrix = N
    addi x5, x0, 0              # k (counter for outer loop)

    Outer:
        addi x6, x5, 1              # j (counter for inner loop)
        fadd.s f0, f0, f0           # initializing f0

        addi x7, x0, 0              # initializing counter
        Normalize: #r_kk = norm(q_k)
            slli x27, x7, 2         # going to x7'th row in Q
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
            slli x27, x7, 2         # going to x7'th row in Q       
            add x27, x5, x27        # go to k'th element in x7'th row
            slli x27, x27, 2        # getting byte address
            add x27, x10, x27       # address of Q[x7][k]
            flw f1, 0(x27)          # f1 = Q[x7][k]
            fdiv.s f1, f1, f0       
            fsw f1 , 0(x27)
            addi x7, x7, 1      
            bltu x7, x28, Update_qk

        # storing r_kk in R
        slli x27, x5, 2             # going to k'th row in R
        add x27, x5, x27            # go to k'th element in k'th row
        slli x27, x27, 2            # getting byte address
        add x27, x11, x27           # address of R[k][k]
        fsw f0, 0(x27)
        fsub.s f0, f0, f0           # resetting f0 

        beq x6, x28, Return         # if j = N, return 

        Inner:
            addi x7, x0, 0              # counter for the dot product loop       
            Dot_Product: # r_kj = q_k * q_j
                slli x27, x7, 2         # going to x7'th row in Q
                add x27, x5, x27        # go to k'th element in x7'th row
                slli x27, x27, 2        # getting byte address
                add x27, x10, x27       # address of Q[x7][k]
                flw f1, 0(x27)          # f1 = Q[x7][k]
                slli x27, x7, 2         # going to x7'th row in Q
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
                slli x27, x7, 2         # going to x7'th row in Q
                add x27, x5, x27        # go to k'th element in x7'th row
                slli x27, x27, 2        # getting byte address
                add x27, x10, x27       # address of Q[x7][k]
                flw f2, 0(x27)          # f2 = Q[x7][k]
                slli x27, x7, 2         # going to x7'th row in Q         
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
            slli x27, x5, 2             # going to k'th row in R
            add x27, x6, x27            # go to j'th element in k'th row
            slli x27, x27, 2            # getting byte address
            add x27, x11, x27           # address of R[k][j]
            fsw f0, 0(x27)              # storing r_kj in its position
            fsub.s f0, f0, f0           # f0 reset

            addi x6, x6, 1              # incrementing counter j
            bltu x6, x28, Inner         # loop if j < N 

        addi x5, x5, 1          # incrementing counter k
        bltu x5, x28, Outer     # loop if k < N

        Return:
            jalr x0, 0(x1)

Tranpose:
    # returns the transpose of a matrix by swapping m[i][j] and m[j][i] entries
    # addi x28, x0, 2     # x28 = size of Q[0] = n
    addi x5, x0, 0      # i = 0, counter for L1

    L1:
        addi x6, x5, 0      # j = i+1, counter for L2

        L2:
            slli x30, x5, 2         # i'th row
            add x30, x6, x30        # j'th entry in i'th row
            slli x30, x30, 2        # getting byte address
            add x30, x10, x30       # &Q[i][j]
            flw f0, 0(x30)          # f0 = Q[i][j]
            slli x31, x6, 2         # j'th row
            add x31, x5, x31        # i'th entry in i'th row
            slli x31, x31, 2        # getting byte address
            add x31, x10, x31       # &Q[j][i]
            flw f1, 0(x31)          # f1 = Q[j][i]

            # swapping Q[i][j] and Q[j][i]
            fsw f0, 0(x31)
            fsw f1, 0(x30)

            addi x6, x6, 1          # j = j + 1
            bltu x6, x28, L2        # loop if j < n

        addi x5, x5, 1      # i = i + 1
        bltu x5, x28, L1    # loop if i < n

    jalr x0, 0(x1)      # return    