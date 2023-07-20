! This program executes pow as a test program using the LC 2200 calling convention
! Check your registers ($v0) and memory to see if it is consistent with this program

        ! vector table
vector0:
        .fill 0x00000000                        ! device ID 0
        .fill 0x00000000                        ! device ID 1
        .fill 0x00000000                        ! ...
        .fill 0x00000000
        .fill 0x00000000
        .fill 0x00000000
        .fill 0x00000000
        .fill 0x00000000                        ! device ID 7
        ! end vector table

main:	lea $sp, initsp                         ! initialize the stack pointer
        lw $sp, 0($sp)                          ! finish initialization

        lea $t0, vector0
        lea $t1, timer_handler
        sw  $t1, 0($t0)

        lea $t1, distance_tracker_handler
        sw  $t1, 1($t0)
        
        lea $t0, minval
        lw  $t0, 0($t0)
        addi $t1, $zero, 65535                  ! store 0000ffff into minval (to make comparisons easier)
        sw  $t1, 0($t0)

        ei                                      ! Enable interrupts

        lea $a0, BASE                           ! load base for pow
        lw $a0, 0($a0)
        lea $a1, EXP                            ! load power for pow
        lw $a1, 0($a1)
        lea $at, POW                            ! load address of pow
        jalr $ra, $at                           ! run pow
        lea $a0, ANS                            ! load base for pow
        sw $v0, 0($a0)

        halt                                    ! stop the program here
        addi $v0, $zero, -1                     ! load a bad value on failure to halt

BASE:   .fill 17
EXP:    .fill 8
ANS:	.fill 0                                 ! should come out to 256 (BASE^EXP)

POW:    addi $sp, $sp, -1                       ! allocate space for old frame pointer
        sw $fp, 0($sp)

        addi $fp, $sp, 0                        ! set new frame pointer

        skpgt $a1, $zero                        ! check if $a1 is zero
        br RET1                                 ! if the exponent is 0, return 1
        skpgt $a0, $zero                        ! if the base is 0, return 0
        br RET0                                 

        addi $a1, $a1, -1                       ! decrement the power

        lea $at, POW                            ! load the address of POW
        addi $sp, $sp, -2                       ! push 2 slots onto the stack
        sw $ra, -1($fp)                         ! save RA to stack
        sw $a0, -2($fp)                         ! save arg 0 to stack
        jalr $ra, $at                           ! recursively call POW
        add $a1, $v0, $zero                     ! store return value in arg 1
        lw $a0, -2($fp)                         ! load the base into arg 0
        lea $at, MULT                           ! load the address of MULT
        jalr $ra, $at                           ! multiply arg 0 (base) and arg 1 (running product)
        lw $ra, -1($fp)                         ! load RA from the stack
        addi $sp, $sp, 2

        br FIN                                  ! unconditional branch to FIN

RET1:   add $v0, $zero, $zero                   ! return a value of 0
	addi $v0, $v0, 1                        ! increment and return 1
        skpgt $v0, $zero                        ! unconditional branch to FIN

RET0:   add $v0, $zero, $zero                   ! return a value of 0

FIN:	lw $fp, 0($fp)                          ! restore old frame pointer
        addi $sp, $sp, 1                        ! pop off the stack
        jalr $zero, $ra

MULT:   add $v0, $zero, $zero                   ! allocate space for old frame pointer
        addi $t0, $zero, 0                      ! sentinel = 0
        addi $s0, $a0, 0
        addi $s1, $a1, 0
        
MULT_WHILE:  
        skpgt $s1, $zero                        ! check if a0 is zero and return
        jalr $zero, $ra

        addi $t0, $zero, 1                        
        nand $t0, $t0, $s1
        nand $t0, $t0, $t0                      ! calculate (a1 & 0x01)

MULT_IF: 
        skpeq $t0, $zero                        ! skip if (a1 % 2 != 1)
        add $v0, $v0, $s0                       ! ans += n   
        
        addi $t0, $zero, 1    
        sll $s0, $s0, $t0                       ! n = n << 1                    
        srl $s1, $s1, $t0                       ! m /= 2
        br MULT_WHILE
                
timer_handler:

        addi $sp, $sp, -1
        sw $k0, 0($sp)                          ! save $k0
        ei                                      ! enable interrupts

        addi $sp, $sp, -3                       ! save processor registers
        sw $t0, 0($sp)
        sw $t1, 1($sp)
        sw $t2, 2($sp)                          

        lea $t0, ticks                          ! execute device code
        lw $t1, 0($t0)
        lw $t2, 0($t1)
        addi $t2, $t2, 1
        sw $t2, 0($t1)                          

        lw $t0, 0($sp)                          ! restore processor registers
        lw $t1, 1($sp)
        lw $t2, 2($sp)
        addi $sp, $sp, 3

        di                                      ! disable interrupts
        lw $k0, 0($sp)
        addi $sp, $sp, 1                        ! restore $k0
        reti                                    ! return from interrupt


distance_tracker_handler:
    addi $sp, $sp, -1
    sw $k0, 0($sp)
    EI

    addi $sp, $sp, -3                       ! save processor registers
    sw $t0, 0($sp)
    sw $t1, 1($sp)
    sw $t2, 2($sp)     
    

    lea $t1, maxval         ! Loading addr[addr[max]] -> t1 
    lw  $t1, 0($t1)         ! Loading addr[max] -> t1 0xFFFC
    lw  $t1, 0($t1)         ! Loading max -> t1

    in  $t2, 1              ! getting input to t2
                            
    skpgt $t2, $t1          ! check if new max
    br notMax               ! if not skip update/save max

    add $t1, $t2, $zero     ! update max in reg
    
    lea $t0, maxval         ! Loading addr[addr[max]] -> t0
    lw  $t0, 0($t0)         ! Loading addr[max] -> t0 0xFFFC
    sw  $t1, 0($t0)         ! Saving newMax(t1) -> mem[0xFFFC]
    br notMin               ! skip setting the min and checking the min condition

notMax:
    lea $t0, minval         ! Loading addr[addr[min]] -> t1 
        lw  $t0, 0($t0)         ! Loading addr[min] -> t1 0xFFFC
        lw  $t0, 0($t0)         ! Loading min -> t1

        skpgt $t0, $t2          ! check if new min
        br notMin               ! if not skip update/save min

        add $t0, $t2, $zero     ! update min in reg

        lea $t1, minval         ! Loading addr[addr[min]] -> t1 
        lw  $t1, 0($t1)         ! Loading addr[min] -> t1 0xFFFC
        sw  $t0, 0($t1)         ! Loading min -> t1
        
notMin:

    lea $t2, minval         ! loading minval
    lw  $t2, 0($t2)
    lw  $t0, 0($t2)

    addi $t2, $zero, 1      ! shifting the min val
    srl $t0, $t0, $t2

    lea $t2, rshift         ! loading the rshift addr
    lw  $t2, 0($t2)         ! loading the rshift location
    sw  $t0, 0($t2)         ! saving to rshift

    lea $t2, maxval         ! loading maxval
    lw  $t2, 0($t2)
    lw  $t0, 0($t2)

    addi $t2, $zero, 1      ! shifting the max val
    sll $t0, $t0, $t2

    lea $t2, lshift         ! loading the lshift addr
    lw  $t2, 0($t2)         ! loading the lshift location
    sw  $t0, 0($t2)         ! saving to lshift

    lw $t0, 0($sp)                          ! restore processor registers
    lw $t1, 1($sp)
    lw $t2, 2($sp)
    addi $sp, $sp, 3

    di                                      ! disable interrupts
    lw $k0, 0($sp)
    addi $sp, $sp, 1                        ! restore $k0
    reti                                    ! return from interrupt


initsp: .fill 0xA000
ticks:  .fill 0xFFFF
lshift: .fill 0xFFFE
rshift: .fill 0xFFFD
maxval: .fill 0xFFFC
minval: .fill 0xFFFB
