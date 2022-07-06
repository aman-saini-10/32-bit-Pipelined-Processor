# 32-bit-Pipelined-Processor
Implemented a 32-bit RISC 5-stage Instruction Pipeline in Verilog, 
<br /> THE REFERENCE FOR THE ISA AND THE PIPELINE OPERATION IN THE GIVEN CODE
<br /> HAS BEEN TAKEN FROM THE BOOK - (Basic Computer Architecture Version 2.1 by Professor Smruti R. Sarangi)
<br /> Processor Supports:
<br />1.) Basic Arithmetic operations
<br />2.) Compare instructions
<br />3.) Branch instructions
<br />4.) Load & Store instructions
<br />5.) Function calls 
<br />6.) Return Instruction.

The Five Stages of Pipeline are- 
<br /> 1.) INSTRUCTION FETCH        
<br /> (Instruction is Fetched from the Memory)
<br />
<br /> 2.) OPERAND FETCH            
<br /> (Instruction is Decoded, and control Signals are generated)
<br />
<br /> 3.) EXECUTION STAGE          
<br /> (This unit performs arithmetic operations required for successful execution of instruction, also computes Branch Target for branch instrucitons)
<br />
<br /> 4.) MEMORY ACCESS            
<br /> (Memory is accessed for load and store instructions)
<br />
<br /> 5.) REGISTER WRITEBACK UNIT  
<br /> (Result is written to the destination register)
