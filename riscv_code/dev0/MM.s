.data
matrix_A: 
.float 0x3D9E01B3, 0x3F313D87, 0xBDE1C7F0, 0x3F2FD415, 0x3E01F9A7, 0xBED71E19, 0x3E90B742, 0x3EFCB165, 
.float 0x3F31C1E9, 0xBD65EF32, 0x3F2727BE, 0x3D643A02, 0x3E87FEB8, 0x3E929874, 0x3F22A2BB, 0xBDF5F0C8, 
.float 0x3D9E01B3, 0x3F313D87, 0xBDE1C7F0, 0x3F2FD415, 0x3E01F9A7, 0xBED71E19, 0x3E90B742, 0x3EFCB165, 
.float 0x3F31C1E9, 0xBD65EF32, 0x3F2727BE, 0x3D643A02, 0x3E87FEB8, 0x3E929874, 0x3F22A2BB, 0xBDF5F0C8, 
.float 0x3D9E01B3, 0xBDBF9C7E, 0x3E33918F, 0x3DE5B48E, 0xBEE8C26F, 0x3EB1E9C5, 0xBDBA12A1, 0x3EB2191C,
.float 0x3D9E01B3, 0xBDBF9C7E, 0x3E33918F, 0x3DE5B48E, 0xBEE8C26F, 0x3EB1E9C5, 0xBDBA12A1, 0x3EB2191C,
.float 0x3D9E01B3, 0xBDBF9C7E, 0x3E33918F, 0x3DE5B48E, 0xBEE8C26F, 0x3EB1E9C5, 0xBDBA12A1, 0x3EB2191C,
.float 0x3D9E01B3, 0xBDBF9C7E, 0x3E33918F, 0x3DE5B48E, 0xBEE8C26F, 0x3EB1E9C5, 0xBDBA12A1, 0x3EB2191C,

matrix_B:

.float 0x414F623A, 0x4168127E, 0x41806161, 0x418CB983, 0x419911A5, 0x41A569C7, 0x41B1C1E9, 0x41BE1A0B,
.float 0x00000000, 0x3FA2DE98, 0x4022DE98, 0x40744DE4, 0x40A2DE98, 0x40CB963E, 0x40F44DE4, 0x410E82C5,
.float 0x00000000, 0x00000000, 0x34DA2B5D, 0x35589195, 0x359FA836, 0x35CDEFE9, 0x36030632, 0x361CB5E8,
.float 0x00000000, 0x00000000, 0x00000000, 0x3388CAC3, 0x33DF3F48, 0x34140AA2, 0x34719B22, 0x348E6AB3,
.float 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x33599E74, 0x33B55962, 0x3311145E, 0x33B5596A,
.float 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x274F3CBF, 0x29010265, 0x28F917EA,
.float 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x28FCD298, 0x28E4D0A2,
.float 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x24FA0253,
matrix_C:   # Result Matrix C
    .float 0, 0, 0, 0,0, 0, 0, 0
    .float 0, 0, 0, 0,0, 0, 0, 0
    .float 0, 0, 0, 0,0, 0, 0, 0
    .float 0, 0, 0, 0,0, 0, 0, 0
    .float 0, 0, 0, 0,0, 0, 0, 0
    .float 0, 0, 0, 0,0, 0, 0, 0
    .float 0, 0, 0, 0,0, 0, 0, 0
    .float 0, 0, 0, 0,0, 0, 0, 0
    
.text
.globl mm

mm:
    # Load matrix addresses into registers
    la x10, matrix_C
    la x11, matrix_A
    la x12, matrix_B  
    addi x28,x0, 0   # initialize x28 to 0
    add x29, x0, x11 # x29 = x11, a temperory register to store the address of matrix A
    jal x1, length   # finds the length of the matrix and stores it in x28
    addi x5,x0,0

L1: addi x6,x0,0
L2: addi x7,x0,0 
    sll x30, x5, x27   # multiplying by size of the row to get the current row
    add x30, x30, x6    # getting the [i,j]th index
    slli x30, x30, 2    # for double precision # byte address
    add x30, x10, x30   # address of [i,j]th index in matrix C
    flw f0, 0(x30)      # f0 = c[i][j]
L3: sll x29, x7, x27     
    add x29, x29, x6 
    slli x29, x29, 2 
    add x29, x12, x29 
    flw f1, 0(x29)      # f1 = b[k][j]
    sll x29, x5, x27 
    add x29, x29, x7 
    slli x29, x29, 2 
    add x29, x11, x29 
    flw f2, 0(x29)      # f2 = a[i][k]
    fmul.s f1, f2, f1
    fadd.s f0, f0, f1
    addi x7, x7, 1
    bltu x7, x28, L3 
    fsw f0, 0(x30)
    addi x6, x6, 1 
    bltu x6, x28, L2 
    addi x5, x5, 1 
    bltu x5, x28, L1

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
        bne  x29, x12, loop1

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