`include "Risc.v"
`timescale 1ns/1ns

module test_bench;
    reg[31:0] addr, addr2, data;
    wire[31:0] out;
    reg write;

    Ram R1(.addr(addr), 
        .addr2(addr2),
        .data(data),
        .out(out),
        .write(write));

    initial begin
        $dumpfile("Ram_test_bench.vcd"); 
        $dumpvars(0, test_bench);
        #50 $finish;
    end

    initial begin
        $monitor($time, " %h", out);
    end

    initial begin
        #2;
        write <= 0; // RESETTING ALL THE INPUT SIGNALS
        addr  <= 32'h00000000;
        addr2 <= 32'h00000000;
        data  <= 32'h00000000;

        #2;
        data  <= 32'h23AD3C17;  
        #2 write <= 1; #1 write <= 0;

        addr2 <= 32'h00000001;
        data  <= 32'h34ADDC17;

        #2 write <= 1; #1 write <= 0;

        addr2 <= 32'h00000002;
        data  <= 32'h3471648A;

        #2 write <= 1; #1 write <= 0;

        addr2 <= 32'h00000003;
        data  <= 32'hFF12414A;

        #2 write <= 1;
        #10 addr  <= 1;
        #10 addr  <= 2;
        #10 addr  <= 3;

    end
    
endmodule