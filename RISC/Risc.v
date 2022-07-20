/* ===============================================

AUTHOR - AMAN SAINI
INDIAN INSTITUTE OF TECHNOLOGY ROPAR

MODEL OF A SIMPLE RISC PROCESSOR

FEATURES - 
1.) 5 STAGE PIPELINE
2.) IN ORDER EXECUTION
3.) 128 KB RAM (2 read ports, 1 write port), SUPPORTS STACK
4.) STATE UPDATE ON (NEGEDGE OF CLK)
5.) NEXT STATE COMPUTATION ON (POSEDGE OF THE CLK)


THE REFERENCE FOR THE ISA AND THE PIPELINE OPERATION IN THE GIVEN CODE
HAS BEEN TAKEN FROM THE BOOK - (Basic Computer Architecture Version 2.1 by Professor Smruti R. Sarangi)
   ===============================================
*/

module Processor(input clk, input reset);

// 14 general purpose registers
// r14 = stack pointer // also called sp
// r15 = return address, will be referred as ra

    reg[31:0] Instruction_MEM[0:1023]; // 4KB INSTRUCTION MEMORY

    reg[31:0] r[0:15], pc;                // REGISTER FILE AND THE PROGRAM COUNTER
    reg flag_E, flag_GT, write;           // FLAGS REGISTER (UPDATED BY THE COMPARE INSTRUCTION), WRITE REGISTER(INPUT TO THE RAM)
    reg[31:0] addr, addr2, addr3, data;   // ADDRESS1, ADDRESS2, DATA INPUTS TO THE RAM
    wire[31:0] buffer, buffer2;           // OUTPUT OF THE RAM GETS STORED IN THE BUFFER REGISTERS (BUFFER REGISTER)
    reg[31:0] branchtarget;               // BRANCH TARGET (IN CASE OF BRANCH INTRUCTION)
    reg isbranchtaken, forA, forB;        // IS-BRANCH-TAKEN => ASSIGNS BRANCHTARGET TO THE PC IN CASE BRANCH IS TAKEN

    Ram R1(addr, addr2, addr3, write, data, buffer, buffer2); // RANDOM ACCESS MEMORY (128 KB WORD ALLIGNED - WORD ADDRESSABLE);

    reg isWb, isBeq, isBgt, isCall, isImm, isLd, isRet, isSt, isUbranch; // CONTROL SIGNALS

     
    
    reg [63:0]  IF_OF; // REGISTER BETWEEN THE INSTRUCTION AND THE OPERAND FETCH STAGE
    reg [200:0] OF_EX; // REGISTER BETWEEN OPERAND FETCH AND EXECUTE STAGE
    reg [136:0] EX_MA; // REGISTER BETWEEN THE EXECUTE AND THE MEMORY ACCCESS STAGE
    reg [136:0] MA_RW; // REGISTER BETWEEN THE MEM ACCESS AND THE REGISTER WRITEBACK STAGE        

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

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            // Setting all the registers to 0 at the beginning of the program
            // This is done to ensure that no register remains in X state once the execution has begun
            flag_E <= 0;
            flag_GT <= 0;

            // Set all the register to 0
            // Now that we know that we have designed a 128 KB ram (word addressable) that means 2^15 memory locations
            // therefore we initialize r[14] the stack pointer to the last location of the Main memory
            r[0]  <= 0;  r[1]  <= 0;  r[2]  <= 0;  r[3]  <= 0;
            r[4]  <= 0;  r[5]  <= 0;  r[6]  <= 0;  r[7]  <= 0;
            r[8]  <= 0;  r[9]  <= 0;  r[10] <= 0;  r[11] <= 0;
            r[12] <= 0;  r[13] <= 0;  r[14] <= 32'h00007FFF;  r[15] <= 0;
            // $r14 represents the stack pointer, hence it is initialized to the last location of the Main Mem
            // $r15 is the return address register, initialized to 0. 
            isWb      <= 0; isBeq  <= 0;  isBgt  <= 0; isCall <= 0; 
            isImm     <= 0; isLd   <= 0;  isRet  <= 0; isSt   <= 0; 
            isUbranch <= 0; pc     <= 0;  isbranchtaken <= 0; // SET ALL THE CONTROL SIGNALS TO 0 STATE
            forA <= 0; forB <= 0;
        end
    end


    // the pipeline registers are populated at the negedge of the clk.

    //INSTRUCTION FETCH STAGE
    always @(negedge clk) begin
        if(!reset) begin // the following operations are carried out, when the reset signal is 0.
            IF_OF[63:32] = pc;
            IF_OF[31:0]  = Instruction_MEM[pc];

            // pc is set on the basis of isbranchtaken signal, 
            // in case isbranch taken is asserted, we update pc to the branch_target.
            // Branch target and the isbranchtaken control signal is evaluated in the <EXECUTE STAGE> (@ posedge of the clk).
            // Therefore, pipeline needs to be stalled for 2 cycles, till the given instruction reaches EX stage
            // This stalling is achieved through 2 no op instructions
            // However there exists certain techniques through which isbranchtaken prediction is carried out in advance based on previous results,
            // But this functionality has not been added in the given code

            pc <= (isbranchtaken == 1) ? branchtarget: pc+1;
        end
    end
    // <INSTRUCTION FETCH STAGE>
//          ________________________________________________________
// IF_OF = |    program counter <32>     |     instruction <32>     | 
//          ````````````````````````````````````````````````````````
//     
//     IF_OF contains program counter and the instruction
    // instruction = {31 opcode 27|26 Imm|25 rd 22|21 rs1 18|17 rs2 14|    }
    // instruction = {31 opcode 27|26 Imm|25 rd 22|21 rs1 18|17 Immediate 0}
    // instruction = {31 opcode 27|26           Immediate(offset)         0}

    // OPERAND FETCH STAGE
    reg[31:0] immx, branch; // immx represents teh sign extended immediate field, which is used when the current intruction is an I type instruction
    reg[31:0] temp1, temp2;
    reg[31:0] A, B, op2;
    always @(posedge clk) begin
        if(!reset) begin


            // CONTROL UNIT 
            // the control unit sets the control signals based on the opcode of the given instruction

            isImm <= IF_OF[26];                        // Set the IsImmediate signal

            if(IF_OF[31:27] == 5'b01111) begin
                isSt <= 1;                             // Set for Store Instruction
            end else isSt <= 0;

            if(IF_OF[31:27] == 5'b01110) begin
                isLd <= 1;                             // Set for load instruction
            end else isLd <= 0;

            if(IF_OF[31:27] == 5'b10100) begin
                isRet <= 1;                            // Set for Return Instruction
            end else isRet <= 0;

            if(IF_OF[31:27] == 5'b10000) begin
                isBeq <= 1;                            // Set for branch is equal Instruction
            end else isBeq <= 0;

            if(IF_OF[31:27] == 5'b10001) begin
                isBgt <= 1;                            // Set for branch is greater than Instruction
            end else isBgt <= 0;

            if(IF_OF[31:27] == 5'b10010) begin
                isUbranch <= 1;                        // Set for Unconditional branch Instruction
            end else isUbranch <= 0;


            if(
            IF_OF[31:27] == 5'b00000 | IF_OF[31:27] == 5'b00001 |      // add and sub
            IF_OF[31:27] == 5'b00010 | IF_OF[31:27] == 5'b00011 |      // mul and div
            IF_OF[31:27] == 5'b00110 | IF_OF[31:27] == 5'b10011 |      // And and call(write return address) 
            IF_OF[31:27] == 5'b00111 | IF_OF[31:27] == 5'b01000 |      // Or  and not
            IF_OF[31:27] == 5'b01001 | IF_OF[31:27] == 5'b01010 |      // mov and lsl
            IF_OF[31:27] == 5'b01011 | IF_OF[31:27] == 5'b01100 |      // lsr and asr
            IF_OF[31:27] == 5'b01110 | IF_OF[31:27] == 5'b00100) begin // load and mod

                isWb <= 1; // Set for all the instruction that writes to registers
            end else isWb <= 0;


            if(IF_OF[31:27] == 5'b10011) begin
                isCall <= 1; // Set for call instruction
            end else isCall <= 0;


            // <CONTROL UNIT>
            // 32 - 18 => 14
            immx[17:0] <= IF_OF[17:0];
            immx[31:18] <= {14{IF_OF[17]}}; // extending the sign of the immediate 

            branch[26:0] <= IF_OF[26:0];
            branch[31:27] <= 5'b00000;
            // in case of branch we do not need to extend the sign, as it is obvious that the address would be a positive number

            // The given implementation updates the pipeline registers on the negedge of the clk, 
            // So right now, we can't store instruction and program counter to OF_EX reg
            // as the instruction in the EX stage would require these fields
            // Neither can we wait for negedge, because at that time, either the next instruction would overwrite IF_OF reg, 
            // or we will violate hold time contraints.



            temp1 = IF_OF[31:0];  // copying INSTRUCTION from IF_OF to TEMP1
            temp2 = IF_OF[63:32]; // copying the PROGRAM COUNTER from IF_OF to TEMP2


            // now we load the A, B, and op2 in temporary registers A, B, op2
            // while loading, we also need to take care about the possible data hazars, and forwarding path from the RW stage.
            // as the instruction in the RW stage, would leave the pipeline in the next cycle,
            // it means that we have to check for the hazards in OF stage itself, otherwise, we will wrongly fetch the operands (in case of possible forwarding)
            // and as the instuction in RW would leave the pipeline, we won't get a chance to fetch the correct values in the EX stage.


            // NOW WE CHECK FOR THE POSSIBLE FORWARDING FROM THE RW STAGE
            if(MA_RW[34:31] == IF_OF[21:18]) begin // Rd of the instruction in RW stage matches rs1 of the instruction in OF stage
                if(MA_RW[40:36] == add  |
                   MA_RW[40:36] == sub  |
                   MA_RW[40:36] == mul  |
                   MA_RW[40:36] == div  |
                   MA_RW[40:36] == mod  |
                   MA_RW[40:36] == and_ |
                   MA_RW[40:36] == or_  |
                   MA_RW[40:36] == not_ |
                   MA_RW[40:36] == mov  |
                   MA_RW[40:36] == lsl  |
                   MA_RW[40:36] == lsr  |
                   MA_RW[40:36] == asr) begin // these instructions modify the value in rd register, 


                    if(IF_OF[31:27] == add | IF_OF[31:27] == sub  | IF_OF[31:27] == mul | IF_OF[31:27] == div | IF_OF[31:27] == mod |
                       IF_OF[31:27] == cmp | IF_OF[31:27] == and_ | IF_OF[31:27] == or_ | IF_OF[31:27] == lsl | IF_OF[31:27] == lsr |
                       IF_OF[31:27] == asr) begin
                            forA <= 1; // <forward A> is asserted
                            A <= MA_RW[72:41]; // A = aluresult
                       end else begin
                            forA <= 0; // <forward A> deasserted (No forwarding required)
                       end       
                end else begin
                    if(MA_RW[40:36] == ld) begin
                        if(IF_OF[31:27] == add | IF_OF[31:27] == sub  | IF_OF[31:27] == mul | IF_OF[31:27] == div | IF_OF[31:27] == mod |
                            IF_OF[31:27] == cmp | IF_OF[31:27] == and_ | IF_OF[31:27] == or_ | IF_OF[31:27] == lsl | IF_OF[31:27] == lsr |
                            IF_OF[31:27] == asr ) begin
                                forA <= 1; // <forward A> is asserted
                                A <= MA_RW[104:73]; // A = ldresult
                            end else begin
                                forA <= 0; // <forward A> deasserted (No forwarding required)
                            end 
                    end else begin
                        forA <= 0; // <forward A> deasserted (No forwarding required)
                    end
                end
            end else begin
                forA <= 0; // when $rd != $rs1 <NO FORWARDING REQUIRED FOR THIS CONDITION>
            end

            // The similar operation is carried out for $rs2
            if(MA_RW[34:31] == IF_OF[17:14] & IF_OF[26] == 1'b0) begin // Rd of the instruction in RW stage matches rs2 of the instruction in OF stage
                if(MA_RW[40:36] == add  |
                   MA_RW[40:36] == sub  |
                   MA_RW[40:36] == mul  |
                   MA_RW[40:36] == div  |
                   MA_RW[40:36] == mod  |
                   MA_RW[40:36] == and_ |
                   MA_RW[40:36] == or_  |
                   MA_RW[40:36] == not_ |
                   MA_RW[40:36] == mov  |
                   MA_RW[40:36] == lsl  |
                   MA_RW[40:36] == lsr  |
                   MA_RW[40:36] == asr) begin


                    if(IF_OF[31:27] == add | IF_OF[31:27] == sub  | IF_OF[31:27] == mul | IF_OF[31:27] == div | IF_OF[31:27] == mod |
                       IF_OF[31:27] == cmp | IF_OF[31:27] == and_ | IF_OF[31:27] == or_ | IF_OF[31:27] == lsl | IF_OF[31:27] == lsr |
                       IF_OF[31:27] == asr | IF_OF[31:27] == mov ) begin
                            B <= MA_RW[72:41]; // B = aluresult
                            forB <= 1; // <forward B> asserted
                       end else begin
                            forB <= 0; // <forward B> deasserted (No forwarding required)
                       end          
                end else begin
                    if(MA_RW[40:36] == ld) begin
                        if(IF_OF[31:27] == add  | IF_OF[31:27] == sub  | IF_OF[31:27] == mul | IF_OF[31:27] == div | IF_OF[31:27] == mod |
                            IF_OF[31:27] == cmp | IF_OF[31:27] == and_ | IF_OF[31:27] == or_ | IF_OF[31:27] == lsl | IF_OF[31:27] == lsr |
                            IF_OF[31:27] == asr | IF_OF[31:27] == mov) begin
                                B <= MA_RW[104:73]; // B = ldresult
                                forB <= 1;
                            end else begin
                                forB <= 0; // <forward B> deasserted (No forwarding required)
                            end
                    end else begin
                        forB <= 0; // <forward B> deasserted (No forwarding required)
                    end
                end
            end else begin
                forB <= 0; // $rs2 != $ rd(in RW stage) {NO FORWARDING REQUIRED}
            end
            
            
        end
    end



    always @(negedge clk) begin
        if(!reset) begin
            // UPDATING THE OF_EX REGISTER ON THE NEGEDGE OF THE CLOCK
            OF_EX[8:0]     <= {isLd, isSt, isRet, isBeq, isBgt, isUbranch, isImm, isCall, isWb}; // the control signals

            OF_EX[72:41]   <= (isSt == 1) ? r[temp1[25:22]] : r[temp1[17:14]]; // value of OP2<32> according to isStore signal 
            if(forA == 1) begin // in case of forwarding
                OF_EX[104:73] <= A;
            end else begin
                OF_EX[104:73]  <= (isRet == 1) ? r[15] : r[temp1[21:18]];  // value of A<32> according to isRet signal
            end
            if(forB == 1) begin
                OF_EX[136:105] <= B;
            end else begin
                OF_EX[136:105] <= (isImm == 1) ? immx : ((isSt == 1) ? r[temp1[25:22]] : r[temp1[17:14]]); // B<32>
            end

            // loading the Sign Extended Immediate into the Instruction Packet
            OF_EX[168:137] <= branch; // BRANCH TARGET
            OF_EX[40:9]    <= temp1;  // INSTRUCTION
            OF_EX[200:169] <= temp2;  // PROGRAM COUNTER
        end
    end
    // <OPERAND FETCH>

    //          ______________________________________________________________________________________________________________________________________________________________________________
    // OF_EX = |         pc<32>        |      branch target<32>     |          B<32>          |          A<32>          |        op2 <32>         |      instruction <32>       |  control<9> |
    //         ````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````
    //         ______________________________________________________________________________________________________________________________________________________________________________
    //        |200                 169|168                      137|136                   105|104                    73|72                     41|40                          9|8           0|
    //        ```````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````
    // instruction = {40 opcode 36|35 Imm|34 rd 31|30 rs1 27|26 rs2 23|    }
    // instruction = {40 opcode 36|35 Imm|34 rd 31|30 rs1 27|26 Immediate 9}
    // instruction = {40 opcode 36|35           Immediate(offset)         9}


    // EXECUTE UNIT-----------------------
    
    reg[31:0] aluresult; // stores the aluresult <temporarily>, at the negedge of the clk, the result is passed on to the EX_MA register
    reg[104:0] temp3;    // temporary buffer to store the fields in the OF_EX stage, that are also required in the EX_MA register

    always @(posedge clk) begin
        if(!reset) begin
            // CHECKING IF THE DATA NEEDS TO BE FORWARDED FROM THE RW STAGE
            // RW -> EX FORWARDING PATH
            if(MA_RW[34:31] == OF_EX[30:27]) begin // Rd of the instruction in RW stage matches rs1 of the instruction in EX stage
                if(MA_RW[40:36] == add  |
                   MA_RW[40:36] == sub  |
                   MA_RW[40:36] == mul  |
                   MA_RW[40:36] == div  |
                   MA_RW[40:36] == mod  |
                   MA_RW[40:36] == and_ |
                   MA_RW[40:36] == or_  |
                   MA_RW[40:36] == not_ |
                   MA_RW[40:36] == mov  |
                   MA_RW[40:36] == lsl  |
                   MA_RW[40:36] == lsr  |
                   MA_RW[40:36] == asr) begin


                    if(OF_EX[40:36] == add | OF_EX[40:36] == sub  | OF_EX[40:36] == mul | OF_EX[40:36] == div | OF_EX[40:36] == mod |
                       OF_EX[40:36] == cmp | OF_EX[40:36] == and_ | OF_EX[40:36] == or_ | OF_EX[40:36] == lsl | OF_EX[40:36] == lsr |
                       OF_EX[40:36] == asr ) begin

                            OF_EX[104:73] = MA_RW[72:41];      // A = aluresult, (in case of possible data forwarding, we just modify the A field in the OF_EX register)
                    end             
                end else begin
                    if(MA_RW[40:36] == ld) begin
                        if(OF_EX[40:36] == add  | OF_EX[40:36] == sub  | OF_EX[40:36] == mul | OF_EX[40:36] == div | OF_EX[40:36] == mod |
                            OF_EX[40:36] == cmp | OF_EX[40:36] == and_ | OF_EX[40:36] == or_ | OF_EX[40:36] == lsl | OF_EX[40:36] == lsr |
                            OF_EX[40:36] == asr ) begin
                                OF_EX[104:73] = MA_RW[104:73]; // A = ldresult, 
                        end     
                    end
                end
            end
            if(MA_RW[34:31] == OF_EX[26:23] & OF_EX[35] == 1'b0) begin // $rd of the instruction in RW stage matches $rs2 of the instruction in EX stage
                if(MA_RW[40:36] == add  |
                   MA_RW[40:36] == sub  |
                   MA_RW[40:36] == mul  |
                   MA_RW[40:36] == div  |
                   MA_RW[40:36] == mod  |
                   MA_RW[40:36] == and_ |
                   MA_RW[40:36] == or_  |
                   MA_RW[40:36] == not_ |
                   MA_RW[40:36] == mov  |
                   MA_RW[40:36] == lsl  |
                   MA_RW[40:36] == lsr  |
                   MA_RW[40:36] == asr) begin


                    if(OF_EX[40:36] == add | OF_EX[40:36] == sub  | OF_EX[40:36] == mul | OF_EX[40:36] == div | OF_EX[40:36] == mod |
                       OF_EX[40:36] == cmp | OF_EX[40:36] == and_ | OF_EX[40:36] == or_ | OF_EX[40:36] == lsl | OF_EX[40:36] == lsr |
                       OF_EX[40:36] == asr | OF_EX[40:36] == mov  ) begin

                            OF_EX[136:105] = MA_RW[72:41]; // B = aluresult, (in case of possible data forwarding, we just modify the B field in the OF_EX register)
                    end             
                end else begin
                    if(MA_RW[40:36] == ld) begin
                        if(OF_EX[40:36] == add  | OF_EX[40:36] == sub  | OF_EX[40:36] == mul | OF_EX[40:36] == div | OF_EX[40:36] == mod |
                            OF_EX[40:36] == cmp | OF_EX[40:36] == and_ | OF_EX[40:36] == or_ | OF_EX[40:36] == lsl | OF_EX[40:36] == lsr |
                            OF_EX[40:36] == asr | OF_EX[40:36] == mov  ) begin
                                OF_EX[136:105] = MA_RW[104:73]; // B = ldresult
                        end     
                    end
                end
            end
            // <\RW -> EX FORWARDING PATH>---------------------------------------------------------
            
            // After, checking for the RW->EX forwarding, we check for the MA->EX forwarding, as the instruction in the MA stage, would be the latest instruction,
            // that would have modified the the values represented by the A and B field.
            
            // CHECKING FOR MA -> EX FORWARDING PATH
            // in case of a ld instruction, we cannot forward the value from the MA stage, (as the value is still begin fetched from the memory at this time)
            // Neither can we forward the value in next cycle from RW stage, as we require the value in this cycle (while instructio is in the EX unit)
            // Therefore we need to stall the pipeline for one cycle (using a no op instruction)

            if(EX_MA[34:31] == OF_EX[30:27]) begin // rs1 of the current instruction equal to the rd of the instruction ahead
                if(EX_MA[40:36] == add  |
                   EX_MA[40:36] == sub  |
                   EX_MA[40:36] == mul  |
                   EX_MA[40:36] == div  |
                   EX_MA[40:36] == mod  |
                   EX_MA[40:36] == and_ |
                   EX_MA[40:36] == or_  |
                   EX_MA[40:36] == not_ |
                   EX_MA[40:36] == mov  |
                   EX_MA[40:36] == lsl  |
                   EX_MA[40:36] == lsr  |
                   EX_MA[40:36] == asr) begin


                    if(OF_EX[40:36] == add | OF_EX[40:36] == sub  | OF_EX[40:36] == mul | OF_EX[40:36] == div | OF_EX[40:36] == mod |
                       OF_EX[40:36] == cmp | OF_EX[40:36] == and_ | OF_EX[40:36] == or_ | OF_EX[40:36] == lsl | OF_EX[40:36] == lsr |
                       OF_EX[40:36] == asr ) begin

                            OF_EX[104:73] = EX_MA[104:73]; // A = aluresult
                    end             
                end 
            end
            if(EX_MA[34:31] == OF_EX[26:23] & OF_EX[35] == 1'b0) begin // rs2 of the current instruction equal to the rd of the instruction ahead
                if(EX_MA[40:36] == add  |
                   EX_MA[40:36] == sub  |
                   EX_MA[40:36] == mul  |
                   EX_MA[40:36] == div  |
                   EX_MA[40:36] == mod  |
                   EX_MA[40:36] == and_ |
                   EX_MA[40:36] == or_  |
                   EX_MA[40:36] == not_ |
                   EX_MA[40:36] == mov  |
                   EX_MA[40:36] == lsl  |
                   EX_MA[40:36] == lsr  |
                   EX_MA[40:36] == asr) begin

                    if(OF_EX[40:36] == add | OF_EX[40:36] == sub  | OF_EX[40:36] == mul | OF_EX[40:36] == div | OF_EX[40:36] == mod |
                       OF_EX[40:36] == cmp | OF_EX[40:36] == and_ | OF_EX[40:36] == or_ | OF_EX[40:36] == lsl | OF_EX[40:36] == lsr |
                       OF_EX[40:36] == asr ) begin

                            OF_EX[136:105] = EX_MA[104:73]; // B = aluresult
                    end             
                end 
            end
            //----------------------------------------------------------------------------------------
            // ARITHMETIC LOGICAL UNIT
            if(OF_EX[40:36] == 5'b00000 | OF_EX[40:36] == 5'b01110 | OF_EX[40:36] == 5'b01111 ) begin
                aluresult <= OF_EX[136:105] + OF_EX[104:73];                               // addition, load and store
            end
            else if(OF_EX[40:36] == 5'b00001) aluresult <= OF_EX[104:73] - OF_EX[136:105]; // subtraction
            else if(OF_EX[40:36] == 5'b00010) aluresult <= OF_EX[136:105] * OF_EX[104:73]; // multiplication
            else if(OF_EX[40:36] == 5'b00011) aluresult <= OF_EX[104:73] / OF_EX[136:105]; // division
            else if(OF_EX[40:36] == 5'b00100) aluresult <= OF_EX[104:73] % OF_EX[136:105]; // modulus

            else if(OF_EX[40:36] == 5'b00101) begin 
            // COMPARE INSTRUCTION
            // WILL SET THE FLAGS
                aluresult = OF_EX[104:73] - OF_EX[136:105];

                if(aluresult == 0) begin
                    flag_E <= 1;
                end else flag_E <= 0;
                if(aluresult > 0) begin
                    flag_GT <= 1;
                end else flag_GT <= 0;
            end

            else if(OF_EX[40:36] == 5'b00110) aluresult <=  OF_EX[136:105] & OF_EX[104:73];  // and instruction
            else if(OF_EX[40:36] == 5'b00111) aluresult <=  OF_EX[136:105] | OF_EX[104:73];  // or instruction
            else if(OF_EX[40:36] == 5'b01000) aluresult <= ~OF_EX[136:105];                  // not instruction
            else if(OF_EX[40:36] == 5'b01001) aluresult <=  OF_EX[136:105];                  // move instruction
            else if(OF_EX[40:36] == 5'b01010) aluresult <=  OF_EX[104:73] << OF_EX[136:105]; // logical shift left
            else if(OF_EX[40:36] == 5'b01011) aluresult <=  OF_EX[104:73] >> OF_EX[136:105]; // logical shift right
            else if(OF_EX[40:36] == 5'b01100) aluresult <=  OF_EX[104:73] >>> OF_EX[136:105];// arithmetic shift right

            // <ARITHMETIC LOGICAL UNIT>
            temp3[8:0]    <= OF_EX[8:0];
            temp3[40:9]   <= OF_EX[40:9];
            temp3[72:41]  <= OF_EX[72:41];
            temp3[104:73] <= OF_EX[200:169];

            // CALCULATING THE BRANCH TARGET
            isbranchtaken <= OF_EX[5]&flag_E | OF_EX[4]&flag_GT | OF_EX[3]; 
            branchtarget  <= (OF_EX[6] == 1) ? OF_EX[104:73] : OF_EX[168:137];
        end
        
    end
    always @(negedge clk) begin
        if(!reset) begin
        EX_MA[8:0] <= temp3[8:0]; // control
        EX_MA[40:9] <= temp3[40:9]; // instruction
        EX_MA[72:41] <= temp3[72:41]; // op2
        EX_MA[104:73] <= aluresult; // aluresult
        EX_MA[136:105] <= temp3[104:73]; // pc
        end
    end
    // <EXECUTE UNIT>

    //          ____________________________________________________________________________________________________________________________
    // EX_MA = |         pc<32>        |       aluresult <32>         |        op2 <32>         |      instruction <32>       |  control<9> |
    //         ``````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````
    //         ____________________________________________________________________________________________________________________________
    //        |136                 105|104                         73|72                     41|40                          9|8           0|
    //        ``````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````

    // MEMORY ACCESS UNIT
    
    
    reg[159:0] latch; // this stage also requires a temporary register to store the fields that are directly passed to the next pipeline register.
    always @(posedge clk) begin

    
        if(!reset) begin
            latch[8:0] <= EX_MA[8:0];        // Control signals from the previous stage
            latch[40:9] <= EX_MA[40:9];      // The intruction
            latch[72:41] <= EX_MA[104:73];   // Aluresult
            latch[104:73] <= EX_MA[136:105]; // Program Counter


            // ACCESS THE RAM TO WRITE TO THE REGISTERS

            if(EX_MA[8]) begin // Load instruction // EX_MA[8] => isLd
                addr3 <= EX_MA[104:73]; // updating the address field of the ram
                write <= 0;             // setting the write signal to 0

            end 
            
            
            else if(EX_MA[7]) begin // STORE INSTRUCTION (REQUIRES DATA FORWARDING PATHS) isSt
            
            // We first put the address of the destination register in Mar Register
            // As the Write port of the Ram is triggered by the `Write Signal
            // Therefore the address must be present in the Mar register before Write gets triggered

            // DATA FORWARDING
            // In case, previous instruction (currently in RW unit) modifies the register, whose
            // value is needed to be stored in the memory, then we need to forward that from the RW unit

            // Now as currently, we have a posedge, so we can find this value in the MA_RW register which was updated on the prev negedge of the clk
            // This register will be next updated on the next negedge of the clk, so we are safe to use it on the posedge of the clk

// for example:-
// ld r1, 15[r3] (value of r1 being modified)
// sw r1, 10[r3] (value of r1 begin stored)
// one possible way would be to insert one no-op instruction
// other would be to forward the value of r1 from RW to MA
            
            
            // the instruction occupies (40 - 9)
            // the opcode is 5 MSB (40, 39, 38, 37, 36)
            // the destination register would be <MA_RW[34:31]>


            // RW -> MA FORWARDING PATH------------
    // instruction = {40 opcode 36|35 Imm|34 rd 31|30 rs1 27|26 rs2 23|    }
    // instruction = {40 opcode 36|35 Imm|34 rd 31|30 rs1 27|26 Immediate 9}
    // instruction = {40 opcode 36|35           Immediate(offset)         9}

                if(MA_RW[34:31] == EX_MA[34:31]) begin // $rd for both the instructions is same
                    // st rd, imm[rs1]
                    if(MA_RW[40:36] == ld) begin
                        data <= MA_RW[104:73]; // ldresult
                    end else if(
                       MA_RW[40:36] == add  |
                       MA_RW[40:36] == sub  |
                       MA_RW[40:36] == mul  |
                       MA_RW[40:36] == div  |
                       MA_RW[40:36] == mod  |
                       MA_RW[40:36] == and_ |
                       MA_RW[40:36] == or_  |
                       MA_RW[40:36] == not_ |
                       MA_RW[40:36] == mov  |
                       MA_RW[40:36] == lsl  |
                       MA_RW[40:36] == lsr  |
                       MA_RW[40:36] == asr) begin
                        data <= MA_RW[72:41]; // aluresult
                    end else begin
                        data <= EX_MA[72:41]; // <NO FORWARIND PATH REQUIRED>
                    end
                end else begin
                    data <= EX_MA[72:41];     // <Rd of the previous instruction does not match the source register of store instruction>
                end
            // ------------------------------------

                
                addr2 = EX_MA[104:73]; // this is computed by the ALU (Memory address)

                // data that has to be stored (possible RAW hazard)

// Blocking Assignment So as to trigger the Write Signal 
// only after correct data is present in MAR, MDR

                write <= 1; // turn on the `Write Signal`

            end else begin
                write <= 0;
                addr2 <= 0;

                data  <= 0;
                addr2 <= 0;

            end
        end
    end
    
    always @(negedge clk) begin
        if(!reset) begin
    // REGISTER UPDATE
        write <= 0;
        MA_RW[8:0] <= latch[8:0];        // control Signals
        MA_RW[40:9] <= latch[40:9];      // instruction
        MA_RW[72:41] <= latch[72:41];    // Aluresult

        MA_RW[104:73] <= buffer;         // LdResult

    // for the load instruction, we access the memory, by updating the read address
    // Once the read address is updated, Ram puts the data into the buffer register
    // This values is accessed at the negedge, when we update the Pipeline registers.

        MA_RW[136:105] <= latch[104:73]; // Program Counter
        end
    end 
    // <MEMORY ACCESS UNIT>



    //          _____________________________________________________________________________________________________________________________
    // MA_RW = |         pc<32>        |       ldresult <32>         |        aluresult <32>     |      instruction <32>       |  control<9> |
    //         ```````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````
    //         _____________________________________________________________________________________________________________________________
    //        |136                 105|104                        73|72                       41|40                          9|8           0|
    //        ```````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````

    // REGISTER WRITEBACK UNIT
    reg[3:0] update_address; //2^4 = 16
    reg[31:0] update_data;
    reg isWb_;
    always @(posedge clk) begin
        if(!reset) begin
            isWb_ <= MA_RW[0];
            if(MA_RW[0] == 1'b1) begin // EX_MA[0] == isWb
                // EX_MA[1] == isCall 
                update_address <= (MA_RW[1] == 1) ? 15 : MA_RW[34:31]; // 15 or rd

            end

            if(MA_RW[1] == 1'b1) begin // isCall ?
                update_data <= MA_RW[136:105];

            end else begin
                if(MA_RW[8] == 1'b1) begin // isld
                    update_data <= MA_RW[104:73]; // ldresult
                end else begin
                    update_data <= MA_RW[72:41];  // aluresult
                end
            end

        end
    end
    always @(negedge clk) begin
        if(!reset) begin
            if(isWb_ == 1'b1) begin
                r[update_address] <= update_data;
            end
        end
    end
    // <REGISTER WRITEBACK UNIT>

endmodule

module Ram( 
        input [31:0] addr,     // Read Address 1 
        input [31:0] addr2,    // Write Address1
        input [31:0] addr3,    // Read Address 2
        input write,           // Write
        input [31:0] data,     // DATA to be written
        output reg[31:0] out,  // output buffer 1
        output reg[31:0] out2);// output buffer 2

    reg[31:0] Mem[0:32767]; // 128 Kb Main Memory

    always @(addr, Mem[addr]) begin
        out <= Mem[addr];
    end
    always @(addr3, Mem[addr3]) begin
        out2 <= Mem[addr3];
    end

    always @(posedge write) begin
        if(write) begin
            Mem[addr2] <= data;
        end
    end
endmodule
