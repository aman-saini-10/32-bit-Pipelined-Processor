`include "Risc.v"
`timescale 1ns/1ns

module test3;

reg clk, reset;

Processor P1(.clk(clk), .reset(reset));
// Note: YOU MAY NEED TO CHANGE THE $finish call BASED ON THE NUMBER YOU ENTER, FOR THE COMPLETE EXECUTION AND THE RIGHT RESULT
initial begin
    $dumpfile("testbench3.vcd");
    $dumpvars(0, test3);
    #30000 $finish;
end
always #5 clk <= ~clk;
initial begin
    reset <= 1;
    clk <= 0;
    #6 reset <= 0;
    #1 P1.r[1] <= 32'h0000002F; // here enter the number which you want to check for prime in hex format
end

initial begin
#5

/*
@ ASSEMBLY PROGRAM TO FIND OUT IF THE NUMBER STORED IN R1 IS A PRIME NUMBER

mov r2, 2

.loop: 
    mod r3, r1, r2  @ divide the number by r2
    cmp r3, 0       @ compare the results with 0 * sets the flag in ALU stage *
    beq.notprime    @ if the result is 0, not prime * uses the flags in the ALU stage *
    
    * 2 no ops * 

    add r2, r2, 1   @ increment r2
    cmp r1, r2      @ compare r2 with the number
    bgt.loop        @ iterate if r2 is smaller
    * 2 no ops *
    mov r0, 1       @ number is prime
b.exit
    * 2 no ops *
.notprime:
    mov r0, 0       @ numner is not prime

.exit:

    // INTRUCTION MANUAL===================================================================================
    parameter // LIST OF ALL THE INTRUCTIONS SUPPORTED BY THE PROCESSOR
    add  =  5'b00000,  // addition
    sub  =  5'b00001,  // subtraction
    mul  =  5'b00010,  // multiplication
    div  =  5'b00011,  // division
    mod  =  5'b00100,  // modulus
    cmp  =  5'b00101,  // compare (set the flag register)
    and_ =  5'b00110,  // bitwise and
    or_  =  5'b00111,  // bitwise or
    not_ =  5'b01000,  // bitwise not
    mov  =  5'b01001,  // move instruction
    lsl  =  5'b01010,  // logical shift left
    lsr  =  5'b01011,  // logical shift right
    asr  =  5'b01100,  // arithmetic shift right
    nop  =  5'b01101,  // no operation
    ld   =  5'b01110,  // load
    st   =  5'b01111,  // store
    beq  =  5'b10000,  // branch if EQ
    bgt  =  5'b10001,  // branch is GT
    b    =  5'b10010,  // Unconditional branch
    call =  5'b10011,  // Function Call
    ret  =  5'b10100;  // Return (load return address to program counter)

    // <INSTRUCTION MANUAL>================================================================================
*/
    P1.Instruction_MEM[0]  <= 32'h4c800002;   // mov r2, 2
    P1.Instruction_MEM[1]  <= 32'h20c48000;   // .loop: mod r3, r1, r2
    P1.Instruction_MEM[2]  <= 32'h2c0c0000;   //        cmp r3, 0
    P1.Instruction_MEM[3]  <= 32'h8000000f;   //        beq .not_prime
    P1.Instruction_MEM[4]  <= 32'h68000000;   //        no op
    P1.Instruction_MEM[5]  <= 32'h68000000;   //        no op
    P1.Instruction_MEM[6]  <= 32'h04880001;   //        add r2, r2, 1
    P1.Instruction_MEM[7]  <= 32'h28048000;   //        cmp r1, r2
    P1.Instruction_MEM[8]  <= 32'h88000001;   //        bgt.loop
    P1.Instruction_MEM[9]  <= 32'h68000000;   //        no op
    P1.Instruction_MEM[10] <= 32'h68000000;   //        no op
    P1.Instruction_MEM[11] <= 32'h4c000001;   //        mov r0, 1
    P1.Instruction_MEM[12] <= 32'h90000010;   //        b.exit
    P1.Instruction_MEM[13] <= 32'h68000000;   //        no op
    P1.Instruction_MEM[14] <= 32'h68000000;   //        no op
                                              //.not_prime:
    P1.Instruction_MEM[15] <= 32'h4c000000;   //        mov r0, 0
                                              //.exit: 
    P1.Instruction_MEM[16] <= 32'h68000000;   // no op


    $monitor("time = ", $time, "ns \nr0  = %h, r1  = %h, r2  = %h, r3  = %h,\nr4  = %h, r5  = %h, r6  = %h, r7  = %h,\nr8  = %h, r9  = %h, r10 = %h, r11 = %h,\nr12 = %h, r13 = %h, r14 = %h, pc = %h, gt = %b, a = %h, b = %h\n",
                    P1.r[0], P1.r[1], P1.r[2],  P1.r[3],  P1.r[4],  P1.r[5],  P1.r[6],  P1.r[7], 
                    P1.r[8], P1.r[9], P1.r[10], P1.r[11], P1.r[12], P1.r[13], P1.r[14], P1.pc);
// register r0 = 1 ==> Prime number
// register r0 = 1 ==> Not a Prime Number
end
endmodule
