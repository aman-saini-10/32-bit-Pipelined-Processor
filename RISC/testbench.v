`include "Risc.v"
`timescale 1ns/1ns

module test;
    reg clk, reset;
    Processor P1(clk, reset);

    initial begin
        $dumpfile("test_bench.vcd");
        $dumpvars(0, test);
        #200 $finish;
    end


    always #5 clk = ~clk;
    initial begin
        reset <= 1;
        clk   <= 0; 
        
        $monitor("time = ", $time, "ns \nr0  = %h, r1  = %h, r2  = %h, r3  = %h,\nr4  = %h, r5  = %h, r6  = %h, r7  = %h,\nr8  = %h, r9  = %h, r10 = %h, r11 = %h,\nr12 = %h, r13 = %h, r14 = %h, r15 = %h \n",
                          P1.r[0], P1.r[1], P1.r[2],  P1.r[3],  P1.r[4],  P1.r[5],  P1.r[6],  P1.r[7], 
                          P1.r[8], P1.r[9], P1.r[10], P1.r[11], P1.r[12], P1.r[13], P1.r[14], P1.r[15]);

        //$monitor("time = ", $time, "\n %h\n %h\n %h\n %h\n %h\n %h\n %h", P1.IF_OF, P1.OF_EX, P1.EX_MA, P1.MA_RW, P1.A, P1.B, P1.op2);        
        # 7 reset <= 0;
    end
    // LET'S STORE THE PROGRAM INTO THE MEMORY FIRST THEN, 
    // WE CAN PROCEED WITH THE EXECUTION IN THE PROCESSOR
    // FOR THIS TESTBENCH WE WILL SIMULATE A SIMPLERISC CODE TO COMPUTE 31*29 - 50

    initial begin
        P1.Instruction_MEM[0] <= 32'h4C40001F; // Mov r1, 31
        P1.Instruction_MEM[1] <= 32'h4C80001D; // Mov r2, 29
        P1.Instruction_MEM[2] <= 32'h10C48000; // Mul r3, r1, r2
        P1.Instruction_MEM[3] <= 32'h0D0C0032; // Sub r4, r3, 50

        #200 $finish;
    end

endmodule
