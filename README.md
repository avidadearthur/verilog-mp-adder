# Design of Hardware Accelerator for Large Integer Arithmetic Operations 
Project done for the class of Complex Digital Design @ Group T - Faculty of Engineering Technology / academic year 2022-23

### Authors:
* [@avidadearthur](https://github.com/avidadearthur)
* [@SandroLyu65](https://github.com/SandroLyu65)

# 1	SUMMARY
In this project, we created digital circuits that can perform 512-bit additions and subtractions with a Maximum Adder Width (MAW) of 128 bits. Additionally, we also included a multiplier circuit that can perform 256-bit multiplications.

# 2	TECHNICAL DESCRIPTION
## 2.1	Addition and Subtraction
We achieved optimal performance with a combination of 4x 2-bit RCAs, 2x 4-bit + 4x 8-bit Carry Look Ahead Adders (CLA), and 3x 16-bit + 1x 32-bit Kogge-Stone Adders (KSA) inside of a Carry Select Adder (CSA) chain. In total, 128-bit operands can be added at a time.

![image](https://github.com/avidadearthur/verilog-mp-adder/assets/42184405/b7a0f3b1-8e8f-4c7e-bf26-d0f424f5cd29)

Figure 1: mp_adder: High-Level Diagram of the final adder.

The top level of the arithmetic circuit is the mp_adder module and some changes have been made to the original Verilog file given to us. First, in addition to the original input and output wires, we have added a new input wire called iAddSub that determines whether the operands are added or subtracted. When iAddSub is 0, the module performs addition. When iAddSub is 1, the module performs subtraction. 

![image](https://github.com/avidadearthur/verilog-mp-adder/assets/42184405/3e34c9eb-048d-4fd8-bd38-32fe88536433)
![image](https://github.com/avidadearthur/verilog-mp-adder/assets/42184405/78ab8864-63bb-47fb-9ece-6bea753c23ae)

Figure 2: uart_top: Code snippet that shows s_COM state (left) and fragment of s_RX state (right) where the rAddSub register value is being set. Note that rAddSub is connected to a mp_adder instance via iAddSub. 

The signal iAddSub arrives at the mp_adder from the uart_top module during its s_COM state, where the first byte of the transmission is checked to be zero, one or two (see 2.2 Multiplication). To achieve this, the FSM of uart_top was extended with an extra state called s_COM. This state comes between s_IDLE and s_COM and it saves the first byte of the transmission in a temporary register called rCom, which is read in a case block to determine rAddSub, which is connected to iAddSub (see Figure 2).
To perform subtraction, the mp_adder module uses a multiplexer (muxB_In and muxB_Out) to invert the bits of the second operand (iOpB) and another multiplexer (muxCarryFirst and muxCarryIn) to control the input carry. This is equivalent to taking the two's complement of iOpB. The resulting value is then added to the first operand (iOpA) using the multi-precision adder (see Figure 3).

![image](https://github.com/avidadearthur/verilog-mp-adder/assets/42184405/78f4d6c1-a98c-4742-8e3b-0c6dd3a6974c)
![image](https://github.com/avidadearthur/verilog-mp-adder/assets/42184405/c83c54ae-0eb2-4a82-b6ed-4f9ecf9c2916)
![image](https://github.com/avidadearthur/verilog-mp-adder/assets/42184405/457cdcb3-ad40-497c-b397-87ad28df2058)
 
Figure 3: mp_adder: Code snippet that computes the two’s complement in case of subtraction.
The second change to the original mp_adder was to replace the N-bit RCA module by a N-bit CSA instance called carry_select_adder_128b. This non-uniform 128-bit CSA module consists of multiple “generate” blocks that instantiate and connect different types of CSA slices as illustrated in Figure 1. In terms of Verilog code, the slices we have are a carry_select_adder_slice_ripple_carry; a carry_select_adder_slice_carry_lookahead_4b; a carry_select_adder_slice_carry_lookahead_8b; and carry_select_adder_slice_ksa_Nb.

![image](https://github.com/avidadearthur/verilog-mp-adder/assets/42184405/518d4b1e-93c8-416d-893e-e8cd4915bec0)
![image](https://github.com/avidadearthur/verilog-mp-adder/assets/42184405/ffaf8fa8-19bd-4199-a58d-bfb12fdca2fe)

Figure 4: kogge_stone_adder_16b: Diagram of the 16-bit Kogge Stone Adder 
Among these four types of slices, the Kogge Stone Adder is the most important component to achieve the positive WNS in 128-bit addition. The Kogge-Stone adder is a parallel prefix form of carry look-ahead adder, and it generates the carry signals in O(log2N) time. We design the structure based on the diagram in Figure 4. There are three main stages within the adder: pre-processing, carry generation and post-processing. The pre-processing stage produces "propagate" and "generate" bits. The carries are produced in the second stage, and these bits are XOR'd with the initial propagate after the input to produce the sum bits.
Inside the carry generation stage, carries are generated fast by computing them in parallel at the cost of increased area. The schematics of yellow and green cells are shown in Figure 4 on the bottom right.

## 2.2	Multiplication
The multiplier circuit used is a 256x256 Vedic Multiplier built in a cascade design that breaks the 256x256 multipliers down to four 128x128 Vedics (See Figure 5) and finally down to 4x4 Wallace Tree Multipliers. 
To derive the 256x256 multiplication result from the four 128x128 multipliers, the multiplicands are multiplied in pairs oALxoBL, oALxoBH, oAHxoBL and oAHxoBH to generate partial products, which are then added together using MP Adders (see Figure6). The MP Adders consist of a 256-bit adder and two 384-bit adders.

![image](https://github.com/avidadearthur/verilog-mp-adder/assets/42184405/581b61a5-dee7-423f-b572-ddf9e65e1144)
![image](https://github.com/avidadearthur/verilog-mp-adder/assets/42184405/b217eb88-3689-4d3f-b14f-49bbe217dd27)

Figure 5 and Figure 6: mp_multiplier: High-Level Diagram of the multiplier circuit (left) mp_multiplier: Diagram of 256x256 multiplier with 4 128x128 multiplier (right)
The structure of the Wallace Tree multiplier can be seen in Figure 7. The partial products are grouped and added in a tree-like structure. Compared to naively adding partial products with regular adders, the benefit of the Wallace tree is its faster speed, which can compute multiplication in O(logN) time.

![image](https://github.com/avidadearthur/verilog-mp-adder/assets/42184405/7556adce-3752-4250-82f7-4afb8ec29a28)

Figure 7: wallace_tree_multiplier: Diagram of 4-bit Wallace Tree Multiplier

To reduce the area cost, we instantiated one 128x128 multiplier, one 256-bit, and one 384-bit mp_adder, which are reused with implemented FSM. The clock cycle latency is sacrificed to save more area.
Similarly, to the subtraction, the multiplication feature was integrated into the FSM of uart_top via the s_COM state. s_COM saves the first byte of the transmission in a temporary register called rCom, which is read in a case block to determine the next state (see Figure 2). If the byte received is a 2 then the FSM knows it will receive operands for multiplication. The uart_top module will then move between states s_RX_MUL and s_WAIT_RX_MUL until NBYTES_MUL has been received. At this point, the actual multiplication can take place in s_MUL.

# 3	PERFORMANCE EVALUATION
The Adder Module (mp_adder)’s post-synthesis report indicated a Worst Negative Slack (WNS) of 0.908ns at 125 MHz clock frequency and MAW of 128-bit. This digital circuit used 1401 LUTs and 1554 Registers according to the post-synthesis utilization report.
The Multiplier Module (mp_multiplier)’s post-synthesis report indicated a WNS of 2.147ns at 125 MHz clock frequency and Operand Width of 256-bit. This digital circuit used 5382 LUTs and 7564 Registers according to the post-synthesis utilization report.

# 4	COMPARISON
We started the project with a Ripple Carry Adder (RCA) as a reference design and tested five other architectures in terms of area costs and Worst Negative Slack (WNS). Table 1 shows a design comparison in terms of WNS performance for MAW of 16, 32, 64 and 128 bit and Table 2 a design comparison in terms of number LUTs and Registers.

Table 1: Worst Negative Slack (WNS) for Different Architectures and Increasing Operand Size
Here's the table formatted as a Markdown table:

| MAW (bits) | 4-bit CLA (ns) | 4-bit RCA in CSA (ns) | 4-bit CLA in CSA (ns) | 8-bit CLA in CSA (ns) | 16-bit KSA in CSA (ns) |
|------------|----------------|----------------------|----------------------|----------------------|-----------------------|
| 16         | 3.761          | 3.430                | 3.861                | 3.627                | 3.487                 |
| 32         | 1.545          | 2.203                | 3.655                | 2.570                | 3.068                 |
| 64         | -1.987         | -0.211               | 2.643                | 1.900                | 2.124                 |
| 128        | -9.556         | -5.053               | -3.199               | -1.293               | 0.632                 |


Let me know if there's anything else I can assist you with!

Table 2: Area Costs in LUTs and Registers for Different Architectures and Increasing Operand Size (including uart_top)
| M   | 4-bit CLA | 4-bit RCA in CSA | 4-bit CLA in CSA | 8-bit CLA in CSA | 16-bit KSA in CSA |
|-----|-----------|------------------|------------------|------------------|-------------------|
| 16  | 1699      | 3200             | 1696             | 3200             | 1715              |
| 32  | 1714      | 3196             | 1694             | 3191             | 1703              |
| 64  | 1761      | 3196             | 1721             | 3184             | 1751              |
| 128 | 1820      | 3175             | 1760             | 3167             | 1775              |


 
 

# 5	DISCUSSION
The comparison of different adder architectures based on Worst Negative Slack (WNS) and area costs has yielded results that are consistent with what we have learned during the Lectures on Complex Digital Design.
As expected, the 4-bit Carry Look-Ahead (CLA) adder outperformed the reference design with Ripple Carry Adders (RCAs). In RCAs, the carry-out from each bit position ripples through to the next, causing a significant delay in the final carry-out signal, especially for larger operand widths. The 4-bit CLA adder, on the other hand, uses a tree structure to calculate the carry-out signal, resulting in a faster carry propagation time and higher operating frequency. However, the 4-bit CLA adder required more gates and wires to implement than the 4-bit RCA adder, making it less area-efficient.
When compared to the subsequent designs that we tested, the 4-bit CLA had the worst delay performance, which was expected because all the later architectures encapsulated other adder blocks within a Carry Select Adder (CSA). The pre-computation of the partial addition for carry 0 and 1 reduced the carry propagation delay. In terms of area costs, we expected the number of LUTs and registers to double, but we suspect that we forgot to set the mp_adder module as the "Top module" before synthesis. Due to time constraints, we did not reproduce the experiment.
We also tested CSAs made with 4-bit RCA, 4-bit CLA, and 8-bit CLA. As expected, the CSAs made with CLA had a better WNS than the CSA with RCA, due to the shorter carry propagation path in the CLA. Interestingly, we noticed that the larger CLA did not improve the WNS, because the combinational circuit to propagate the carry became too large. Regarding the area cost difference, we did not notice significant variation.
To achieve a positive WNS at a 128-bit MAW, we decided to investigate a new architecture by combining a 16-bit Kogge-Stone Adder (KSA) with the CSA chain. We found that the KSA's intrinsic speed and its ability to parallelize the computation made it a better choice compared to the CLA inside of the CSA. The KSA generates all the carries in parallel without any ripple, leading to a faster computation and less delay compared to the CLA, which has a longer carry propagation path.
We took our exploration of CSA adders further by experimenting with varying the size and composition of the CSA slices. Our efforts resulted in the development of the Variable-Sized CSA, which outperformed the uniform CSA with 16-bit KSA slices in terms of timing performance. Specifically, we achieved a positive WNS of 0.908ns, which is significantly better than the 0.632ns achieved by the uniform CSA. Additionally, the Variable-Sized CSA required relatively low LUTs, making it more area-efficient. The efficiency is due to the smaller blocks in the beginning that have a big role in the total delay. However, the Variable-Sized Carry Select adder has the disadvantage of being difficult to scale the adder width, making it less flexible for different operand widths.

# 6	REFERENCES
[1] Esa, Mohd & Achyut, Konasagar. (2019). Design and Verification of 4 X 4 Wallace Tree Multiplier. 10.5281/zenodo.3757325.
[2] Golla, Nagaraju, and GV Subba Reddy. "Design and Implementation of 128 x 128 Bit Multiplier by Ancient Mathematics."
[3] U. Penchalaiah and S. K. VG, "Design of High-Speed and Energy-Efficient Parallel Prefix Kogge Stone Adder," 2018 IEEE International Conference on System, Computation, Automation and Networking (ICSCA), Pondicherry, India, 2018, pp. 1-7, doi: 10.1109/ICSCAN.2018.8541143.
