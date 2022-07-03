# 32-bit-Pipelined-Processor
Implemented a 32-bit RISC 5-stage Instruction Pipeline in Verilog, 

Processor Supports:
<br />1.) Basic Arithmetic operations
<br />2.) Compare instructions
<br />3.) Branch instructions
<br />4.) Load & Store instructions
<br />5.) Function calls 
<br />6.) Return Instruction.

The Five Stages of Pipeline are- 
<br /> 1.) INSTRUCTION FETCH        (Instruction is Fetched from the Memory)
<br /> 2.) OPERAND FETCH            (Instruction is Decoded, and control Signals are generated)
<br /> 3.) EXECUTION STAGE          (This unit performs arithmetic operations required for successful execution of instruction, also computes Branch Target for branch instrucitons)
<br /> 4.) MEMORY ACCESS            (Memory is accessed for load and store instructions)
<br /> 5.) REGISTER WRITEBACK UNIT  (RESULTS ARE WRITTEN BACK TO THE REGISTERS)
