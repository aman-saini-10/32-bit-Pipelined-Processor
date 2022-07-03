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

                          
        # 50 reset <= 0;
    end
    // LET'S STORE THE PROGRAM INTO THE MEMORY FIRST THEN, 
    // WE CAN PROCEED WITH THE EXECUTION IN THE PROCESSOR
    // FOR THIS TESTBENCH WE WILL SIMULATE A SIMPLERISC CODE TO COMPUTE 31*29 - 50

    initial begin
        P1.write    <= 0; // Set the Write Signal to 0
        P1.addr2    <= 0; // Set the address of the first instruction as 0
        P1.data     <= 32'h4C40001F; #1; // Mov r1, 31
        P1.write    <= 1; #1; 

        P1.addr2    <= 1;
        P1.data     <= 32'h4C80001D;    // Mov r2, 29
        P1.write    <= 0; #1;
        P1.write    <= 1; #1; 


        // PROCESSOR NEEDS TO BE STALLED FOR 3 CYCLES TO PREVENT RAW DEPENDENCY

        P1.addr2    <= 2; 
        P1.data     <= 32'h68000000; //no operation
        P1.write    <= 0; #1;
        P1.write    <= 1; #1; 
                
        P1.addr2    <= 3; 
        P1.data     <= 32'h68000000; //no operation
        P1.write    <= 0; #1;
        P1.write    <= 1; #1; 

        P1.addr2    <= 4; 
        P1.data     <= 32'h68000000; //no operation
        P1.write    <= 0; #1;
        P1.write    <= 1; #1; 

        P1.addr2    <= 5; 
        P1.data     <= 32'h10C48000; // Mul r3, r1, r2
        P1.write    <= 0; #1;
        P1.write    <= 1; #1; 

        // STALL BEGIN

        P1.addr2    <= 6; 
        P1.data     <= 32'h68000000; //no operation
        P1.write    <= 0; #1;
        P1.write    <= 1; #1; 

        P1.addr2    <= 7; 
        P1.data     <= 32'h68000000; //no operation
        P1.write    <= 0; #1;
        P1.write    <= 1; #1; 

        P1.addr2    <= 8; 
        P1.data     <= 32'h68000000; //no operation
        P1.write    <= 0; #1;
        P1.write    <= 1; #1; 

        P1.addr2    <= 9;
        P1.data     <= 32'h0D0C0032; // Sub r4, r3, 50
        P1.write    <= 0; #1;
        P1.write    <= 1;
    end

    

endmodule