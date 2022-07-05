`include "Risc.v"
`timescale 1ns/1ns

module test2;

reg clk, reset;
Processor P1(clk, reset);

initial begin
    $dumpfile("test_bench2.vcd");
    $dumpvars(0, test2);
    #2000 $finish;
end

always #5 clk = ~clk;

initial begin
    reset <= 1;
    clk <= 0;

    // LOADING THE INSTRUCTIONS
    // program to compute the factorial of a number stored in r0
    P1.Instruction_MEM[0] <= 32'h4C00000A; // mov r0, 10
    P1.Instruction_MEM[1] <= 32'h4C400001; // mov r1, 1
    P1.Instruction_MEM[2] <= 32'h68000000; // no op
    P1.Instruction_MEM[3] <= 32'h68000000; // no op
    P1.Instruction_MEM[4] <= 32'h48800000; // mov r2, r0 
    // .loop
    P1.Instruction_MEM[5] <= 32'h68000000; // no op
    P1.Instruction_MEM[6] <= 32'h68000000; // no op
    P1.Instruction_MEM[7] <= 32'h68000000; // no op 
    P1.Instruction_MEM[8] <= 32'h10448000; //         mul r1, r1, r2
    P1.Instruction_MEM[9] <= 32'h0C880001; //         sub r2, r2, 1
    P1.Instruction_MEM[10] <= 32'h68000000; // no op
    P1.Instruction_MEM[11] <= 32'h68000000; // no op
    P1.Instruction_MEM[12] <= 32'h68000000; // no op
    P1.Instruction_MEM[13] <= 32'h2C080001; //         cmp r2, 1
    P1.Instruction_MEM[14] <= 32'h68000000; // no op
    P1.Instruction_MEM[15] <= 32'h68000000; // no op
    P1.Instruction_MEM[16] <= 32'h68000000; // no op
    P1.Instruction_MEM[17] <= 32'h88000005; //         bgt.loop
    P1.Instruction_MEM[18] <= 32'h68000000; // no op
    P1.Instruction_MEM[19] <= 32'h68000000; // no op



    $monitor("time = ", $time, "ns \nr0  = %h, r1  = %h, r2  = %h, r3  = %h,\nr4  = %h, r5  = %h, r6  = %h, r7  = %h,\nr8  = %h, r9  = %h, r10 = %h, r11 = %h,\nr12 = %h, r13 = %h, r14 = %h, pc = %h\n",
                    P1.r[0], P1.r[1], P1.r[2],  P1.r[3],  P1.r[4],  P1.r[5],  P1.r[6],  P1.r[7], 
                    P1.r[8], P1.r[9], P1.r[10], P1.r[11], P1.r[12], P1.r[13], P1.r[14], P1.pc);

    //$monitor("time = ", $time, "isbranchtaken = %b, Flag_E = %b, Flag_GT = %b, isbeq = %b, isbgt = %b, isUbranch = %b, branchtarget = %h, pc = %h", P1.isbranchtaken, P1.flag_E, P1.flag_GT, P1.isBeq, P1.isBgt, P1.isUbranch, P1.branchtarget, P1.pc);
    
    #5 reset <= 0;

end

endmodule