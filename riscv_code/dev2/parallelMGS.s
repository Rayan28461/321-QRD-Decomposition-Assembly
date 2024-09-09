.data
    matrix_A:   # Input Matrix 
        .float 1, 2, 3, 4, 5, 6, 7, 8
        .float 9,10,11,12,13,14,15,16        
        .float 1, 2, 3, 4, 5, 6, 7, 8
        .float 9,10,11,12,13,14,15,16
        .float 1, 1, 1, 1, 1, 1, 1, 1
        .float 1, 1, 1, 1, 1, 1, 1, 1
        .float 1, 1, 1, 1, 1, 1, 1, 1
        .float 1, 1, 1, 1, 1, 1, 1, 1

    result:   # Result Matrix 
        .float 0, 0, 0, 0, 0, 0, 0, 0
        .float 0, 0, 0, 0, 0, 0, 0, 0 
        .float 0, 0, 0, 0, 0, 0, 0, 0
        .float 0, 0, 0, 0, 0, 0, 0, 0
        .float 0, 0, 0, 0, 0, 0, 0, 0
        .float 0, 0, 0, 0, 0, 0, 0, 0 
        .float 0, 0, 0, 0, 0, 0, 0, 0
        .float 0, 0, 0, 0, 0, 0, 0, 0

.text
.globl MGS

MGS: 
    # loading the addresses of the data in registers
    la x10, matrix_A            
    la x11, result
    addi x28, x0, 8             # x28 = size of the matrix = N
    addi x5, x0, 0              # k (counter for outer loop)

Outer:
    # addi x6, x0, 0

    # initializing f registers for process p
    fadd.s f0, f0, f0           # initializing f0
    fadd.s f3, f0, f0           # initializing f0 for p2
    fadd.s f6, f0, f0           # initializing f0 for p3
    fadd.s f9, f0, f0           # initializing f0 for p4
    fadd.s f12, f0, f0          # initializing f0 for p5
    fadd.s f15, f0, f0          # initializing f0 for p6
    fadd.s f18, f0, f0          # initializing f0 for p7


    addi x7, x0, 0              # initializing counter
    Normalize: #r_kk = norm(q_k)
        slli x27, x7, 3         # going to x7'th row in Q
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
        slli x27, x7, 3         # going to x7'th row in Q       
        add x27, x5, x27        # go to k'th element in x7'th row
        slli x27, x27, 2        # getting byte address
        add x27, x10, x27       # address of Q[x7][k]
        flw f1, 0(x27)          # f1 = Q[x7][k]
        fdiv.s f1, f1, f0       
        fsw f1 , 0(x27)
        addi x7, x7, 1      
        bltu x7, x28, Update_qk

    # storing r_kk in R
    slli x27, x5, 3             # going to k'th row in R
    add x27, x5, x27            # go to k'th element in k'th row
    slli x27, x27, 2            # getting byte address
    add x27, x11, x27           # address of R[k][k]
    fsw f0, 0(x27)
    fsub.s f0, f0, f0           # resetting f0 

    # initializing counters for each process p
    addi x7, x0, 0              # counter for p1
    addi x8, x0, 0              # counter for p2
    addi x9, x0, 0              # counter for p3
    addi x20, x0, 0             # counter for p4
    addi x29, x0, 0             # counter for p5
    addi x30, x0, 0             # counter for p6               
    addi x31, x0, 0             # counter for p7

    addi x6, x28, -1
    beq x5, x6, Exit            # if k = n - 1, exit
    # beq x6, x28, Exit           # if j = N, exit
#########################################################################################
    parallel_Inner:
        Op1:
        # ...
        addi x6, x0, 1
        bge x5, x6, Op2

        # Operating on q_j; j = 1
        Dot_Product_1: # r_k1 = q_k * q_1
            slli x27, x7, 3         # going to x7'th row in Q
            add x27, x5, x27        # go to k'th element in x7'th row
            slli x27, x27, 2        # getting byte address
            add x27, x10, x27       # address of Q[x7][k]
            flw f1, 0(x27)          # f1 = Q[x7][k]
            slli x27, x7, 3         # going to x7'th row in Q
            addi x27, x27, 1        # go to 1'st element in x7'th row
            slli x27, x27, 2        # getting byte address
            add x27, x10, x27       # address of Q[x7][1]
            flw f2, 0(x27)          # f2 = Q[x7][1]
            fmul.s f1, f2, f1
            fadd.s f0, f1, f0       # f0 = r_k1
            addi x7, x7, 1          # updating counter
            bltu x7, x28, Dot_Product_1

        addi x7, x0, 0              # resetting counter       
        Update_q1:  
            slli x27, x7, 3         # going to x7'th row in Q
            add x27, x5, x27        # go to k'th element in x7'th row
            slli x27, x27, 2        # getting byte address
            add x27, x10, x27       # address of Q[x7][k]
            flw f2, 0(x27)          # f2 = Q[x7][k]
            slli x27, x7, 3         # going to x7'th row in Q         
            addi x27, x27, 1        # go to 1'st element in x7'th row
            slli x27, x27, 2        # getting byte address
            add x27, x10, x27       # address of Q[x7][1]
            flw f1, 0(x27)          # f1 = Q[x7][1]
            fmul.s f2, f0, f2
            fsub.s f1, f1, f2       # calculating q_1 = q_1 - r_k1 * q_k
            fsw f1, 0(x27)          # updating Q[x7][1]
            addi x7, x7, 1          # updating counter
            bltu x7, x28, Update_q1

        # storing r_k1 in R
        slli x27, x5, 3             # going to k'th row in R
        addi x27, x27, 1            # go to 1'st element in k'th row
        slli x27, x27, 2            # getting byte address
        add x27, x11, x27           # address of R[k][1]
        fsw f0, 0(x27)              # storing r_k1 in its position
        fsub.s f0, f0, f0           # f0 reset

        #############################
        #############################
        Op2:
        # ...
        addi x6, x0, 2
        bge x5, x6, Op3

        # Operating on q_j; j = 2
        Dot_Product_2: # r_k2 = q_k * q_2
            slli x26, x8, 3         # going to x8'th row in Q
            add x26, x5, x26        # go to k'th element in x8'th row
            slli x26, x26, 2        # getting byte address
            add x26, x10, x26       # address of Q[x8][k]
            flw f4, 0(x26)          # f4 = Q[x8][k]
            slli x26, x8, 3         # going to x8'th row in Q
            addi x26, x26, 2        # go to 2'nd element in x8'th row
            slli x26, x26, 2        # getting byte address
            add x26, x10, x26       # address of Q[x8][2]
            flw f5, 0(x26)          # f5 = Q[x8][2]
            fmul.s f4, f5, f4
            fadd.s f3, f4, f3       # f3 = r_k2
            addi x8, x8, 1          # updating counter
            bltu x8, x28, Dot_Product_2

        addi x8, x0, 0              # resetting counter       
        Update_q2:  
            slli x26, x8, 3         # going to x8'th row in Q
            add x26, x5, x26        # go to k'th element in x8'th row
            slli x26, x26, 2        # getting byte address
            add x26, x10, x26       # address of Q[x8][k]
            flw f5, 0(x26)          # f5 = Q[x8][k]
            slli x26, x8, 3         # going to x8'th row in Q         
            addi x26, x26, 2        # go to 2'nd element in x8'th row
            slli x26, x26, 2        # getting byte address
            add x26, x10, x26       # address of Q[x8][2]
            flw f4, 0(x26)          # f4 = Q[x8][2]
            fmul.s f5, f3, f5
            fsub.s f4, f4, f5       # calculating q_2 = q_2 - r_k2 * q_k
            fsw f4, 0(x26)          # updating Q[x8][2]
            addi x8, x8, 1          # updating counter
            bltu x8, x28, Update_q2

        # storing r_k2 in R
        slli x26, x5, 3             # going to k'th row in R
        addi x26, x26, 2            # go to 2'nd element in k'th row
        slli x26, x26, 2            # getting byte address
        add x26, x11, x26           # address of R[k][2]
        fsw f3, 0(x26)              # storing r_k2 in its position
        fsub.s f3, f3, f3           # f3 reset

        #############################
        #############################
        Op3:
        # ...
        addi x6, x0, 3
        bge x5, x6, Op4

        # Operating on q_j; j = 3
        Dot_Product_3: # r_k3 = q_k * q_3
            slli x25, x9, 3         # going to x9'th row in Q
            add x25, x5, x25        # go to k'th element in x9'th row
            slli x25, x25, 2        # getting byte address
            add x25, x10, x25       # address of Q[x9][k]
            flw f7, 0(x25)          # f7 = Q[x9][k]
            slli x25, x9, 3         # going to x9'th row in Q
            addi x25, x25, 3        # go to 3'rd element in x9'th row
            slli x25, x25, 2        # getting byte address
            add x25, x10, x25       # address of Q[x9][3]
            flw f8, 0(x25)          # f8 = Q[x9][3]
            fmul.s f7, f8, f7
            fadd.s f6, f7, f6       # f6 = r_k3
            addi x9, x9, 1          # updating counter
            bltu x9, x28, Dot_Product_3

        addi x9, x0, 0              # resetting counter       
        Update_q3:  
            slli x25, x9, 3         # going to x9'th row in Q
            add x25, x5, x25        # go to k'th element in x9'th row
            slli x25, x25, 2        # getting byte address
            add x25, x10, x25       # address of Q[x9][k]
            flw f8, 0(x25)          # f8 = Q[x9][k]
            slli x25, x9, 3         # going to x9'th row in Q         
            addi x25, x25, 3        # go to 3'rd element in x9'th row
            slli x25, x25, 2        # getting byte address
            add x25, x10, x25       # address of Q[x9][3]
            flw f7, 0(x25)          # f7 = Q[x9][3]
            fmul.s f8, f6, f8
            fsub.s f7, f7, f8       # calculating q_3 = q_3 - r_k3 * q_k
            fsw f7, 0(x25)          # updating Q[x9][3]
            addi x9, x9, 1          # updating counter
            bltu x9, x28, Update_q3

        # storing r_k3 in R
        slli x25, x5, 3             # going to k'th row in R
        addi x25, x25, 3            # go to 3'rd element in k'th row
        slli x25, x25, 2            # getting byte address
        add x25, x11, x25           # address of R[k][3]
        fsw f6, 0(x25)              # storing r_k3 in its position
        fsub.s f6, f6, f6           # f6 reset

        #############################
        #############################
        Op4:
        # ...
        addi x6, x0, 4
        bge x5, x6, Op5

        # Operating on q_j; j = 4
        Dot_Product_4: # r_k4 = q_k * q_4
            slli x24, x20, 3         # going to x20'th row in Q
            add x24, x5, x24        # go to k'th element in x20'th row
            slli x24, x24, 2        # getting byte address
            add x24, x10, x24       # address of Q[x20][k]
            flw f10, 0(x24)          # f10 = Q[x20][k]
            slli x24, x20, 3         # going to x20'th row in Q
            addi x24, x24, 4        # go to 4'th element in x20'th row
            slli x24, x24, 2        # getting byte address
            add x24, x10, x24       # address of Q[x20][4]
            flw f11, 0(x24)          # f11 = Q[x20][4]
            fmul.s f10, f11, f10
            fadd.s f9, f10, f9       # f9 = r_k4
            addi x20, x20, 1          # updating counter
            bltu x20, x28, Dot_Product_4

        addi x20, x0, 0              # resetting counter       
        Update_q4:  
            slli x24, x20, 3         # going to x20'th row in Q
            add x24, x5, x24        # go to k'th element in x20'th row
            slli x24, x24, 2        # getting byte address
            add x24, x10, x24       # address of Q[x20][k]
            flw f11, 0(x24)          # f11 = Q[x20][k]
            slli x24, x20, 3         # going to x20'th row in Q         
            addi x24, x24, 4        # go to 4'th element in x20'th row
            slli x24, x24, 2        # getting byte address
            add x24, x10, x24       # address of Q[x20][4]
            flw f10, 0(x24)          # f10 = Q[x20][4]
            fmul.s f11, f9, f11
            fsub.s f10, f10, f11       # calculating q_4 = q_4 - r_k4 * q_k
            fsw f10, 0(x24)          # updating Q[x20][4]
            addi x20, x20, 1          # updating counter
            bltu x20, x28, Update_q4

        # storing r_k4 in R
        slli x24, x5, 3             # going to k'th row in R
        addi x24, x24, 4            # go to 4'th element in k'th row
        slli x24, x24, 2            # getting byte address
        add x24, x11, x24           # address of R[k][4]
        fsw f9, 0(x24)              # storing r_k4 in its position
        fsub.s f9, f9, f9           # f9 reset

        #############################
        #############################
        Op5:
        # ...
        addi x6, x0, 5
        bge x5, x6, Op6

        # Operating on q_j; j = 5
        Dot_Product_5: # r_k5 = q_k * q_5
            slli x23, x29, 3         # going to x29'th row in Q
            add x23, x5, x23        # go to k'th element in x29'th row
            slli x23, x23, 2        # getting byte address
            add x23, x10, x23       # address of Q[x29][k]
            flw f7, 0(x23)          # f7 = Q[x29][k]
            slli x23, x29, 3         # going to x29'th row in Q
            addi x23, x23, 5        # go to 5'th element in x29'th row
            slli x23, x23, 2        # getting byte address
            add x23, x10, x23       # address of Q[x29][5]
            flw f8, 0(x23)          # f8 = Q[x29][5]
            fmul.s f7, f8, f7
            fadd.s f12, f7, f12       # f12 = r_k5
            addi x29, x29, 1          # updating counter
            bltu x29, x28, Dot_Product_5

        addi x29, x0, 0              # resetting counter       
        Update_q5:  
            slli x23, x29, 3         # going to x29'th row in Q
            add x23, x5, x23        # go to k'th element in x29'th row
            slli x23, x23, 2        # getting byte address
            add x23, x10, x23       # address of Q[x29][k]
            flw f8, 0(x23)          # f8 = Q[x29][k]
            slli x23, x29, 3         # going to x29'th row in Q         
            addi x23, x23, 5        # go to 5'th element in x29'th row
            slli x23, x23, 2        # getting byte address
            add x23, x10, x23       # address of Q[x29][5]
            flw f7, 0(x23)          # f7 = Q[x29][5]
            fmul.s f8, f12, f8
            fsub.s f7, f7, f8       # calculating q_5 = q_5 - r_k5 * q_k
            fsw f7, 0(x23)          # updating Q[x29][5]
            addi x29, x29, 1          # updating counter
            bltu x29, x28, Update_q5

        # storing r_k3 in R
        slli x23, x5, 3             # going to k'th row in R
        addi x23, x23, 5            # go to 5'th element in k'th row
        slli x23, x23, 2            # getting byte address
        add x23, x11, x23           # address of R[k][5]
        fsw f12, 0(x23)              # storing r_k5 in its position
        fsub.s f12, f12, f12           # f12 reset

        #############################
        #############################
        Op6:
        # ...
        addi x6, x0, 6
        bge x5, x6, Op7

        # Operating on q_j; j = 6
        Dot_Product_6: # r_k6 = q_k * q_6
            slli x22, x30, 3         # going to x30'th row in Q
            add x22, x5, x22        # go to k'th element in x30'th row
            slli x22, x22, 2        # getting byte address
            add x22, x10, x22       # address of Q[x30][k]
            flw f16, 0(x22)          # f16 = Q[x30][k]
            slli x22, x30, 3         # going to x30'th row in Q
            addi x22, x22, 6        # go to 6'th element in x30'th row
            slli x22, x22, 2        # getting byte address 
            add x22, x10, x22       # address of Q[x30][6]
            flw f17, 0(x22)          # f17 = Q[x30][6]
            fmul.s f16, f17, f16
            fadd.s f15, f16, f15       # f15 = r_k6
            addi x30, x30, 1          # updating counter
            bltu x30, x28, Dot_Product_6

        addi x30, x0, 0              # resetting counter       
        Update_q6:  
            slli x22, x30, 3         # going to x30'th row in Q
            add x22, x5, x22        # go to k'th element in x30'th row
            slli x22, x22, 2        # getting byte address
            add x22, x10, x22       # address of Q[x30][k]
            flw f17, 0(x22)          # f17 = Q[x30][k]
            slli x22, x30, 3         # going to x30'th row in Q         
            addi x22, x22, 6        # go to 6'th element in x30'th row
            slli x22, x22, 2        # getting byte address
            add x22, x10, x22       # address of Q[x30][6]
            flw f16, 0(x22)          # f16 = Q[x30][6]
            fmul.s f17, f15, f17
            fsub.s f16, f16, f17       # calculating q_6 = q_6 - r_k6 * q_k
            fsw f16, 0(x22)          # updating Q[x30][6]
            addi x30, x30, 1          # updating counter
            bltu x30, x28, Update_q6

        # storing r_k6 in R
        slli x22, x5, 3             # going to k'th row in R
        addi x22, x22, 6            # go to 6'th element in k'th row
        slli x22, x22, 2            # getting byte address
        add x22, x11, x22           # address of R[k][6]
        fsw f15, 0(x22)              # storing r_k6 in its position
        fsub.s f15, f15, f15           # f15 reset

        #############################
        #############################
        Op7:
        # # ...
        # addi x6, x0, 7
        # bge x5, x6, Op4

        # Operating on q_j; j = 7
        Dot_Product_7: # r_k7 = q_k * q_7
            slli x21, x31, 3         # going to x31'th row in Q
            add x21, x5, x21        # go to k'th element in x31'th row
            slli x21, x21, 2        # getting byte address
            add x21, x10, x21       # address of Q[x31][k]
            flw f19, 0(x21)          # f19 = Q[x31][k]
            slli x21, x31, 3         # going to x31'th row in Q
            addi x21, x21, 7        # go to 7'th element in x31'th row
            slli x21, x21, 2        # getting byte address
            add x21, x10, x21       # address of Q[x31][7]
            flw f20, 0(x21)          # f20 = Q[x31][7]
            fmul.s f19, f20, f19
            fadd.s f18, f19, f18       # f18 = r_k7
            addi x31, x31, 1          # updating counter
            bltu x31, x28, Dot_Product_7

        addi x31, x0, 0              # resetting counter       
        Update_q7:  
            slli x21, x31, 3         # going to x31'th row in Q
            add x21, x5, x21        # go to k'th element in x31'th row
            slli x21, x21, 2        # getting byte address
            add x21, x10, x21       # address of Q[x31][k]
            flw f20, 0(x21)          # f20 = Q[x31][k]
            slli x21, x31, 3         # going to x31'th row in Q         
            addi x21, x21, 7        # go to 7'th element in x31'th row
            slli x21, x21, 2        # getting byte address
            add x21, x10, x21       # address of Q[x31][7]
            flw f19, 0(x21)          # f19 = Q[x31][7]
            fmul.s f20, f18, f20
            fsub.s f19, f19, f20       # calculating q_7 = q_7 - r_k7 * q_k
            fsw f19, 0(x21)          # updating Q[x31][7]
            addi x31, x31, 1          # updating counter
            bltu x31, x28, Update_q7

        # storing r_k7 in R
        slli x21, x5, 3             # going to k'th row in R
        addi x21, x21, 7            # go to 7'th element in k'th row
        slli x21, x21, 2            # getting byte address
        add x21, x11, x21           # address of R[k][7]
        fsw f18, 0(x21)              # storing r_k7 in its position
        fsub.s f18, f18, f18           # f18 reset

############################################################################################
        # addi x6, x6, 1              # incrementing counter j
        # bltu x6, x28, Inner         # loop if j < N 

    addi x5, x5, 1          # incrementing counter k
    bltu x5, x28, Outer     # loop if k < N

Exit:
    addi x10, x0, 10
    ecall