python3 ./matrix-hex/golden_gen.py
iverilog -o TB_MAC_TOP.vvp ../src/MAC_1X1_UNIT.v ../src/MAC_4X1_COL.v ../src/MAC_4X4_ARRAY.v ../src/MAC_TOP.v ../src/SRAM.v TB_MAC_TOP.v
vvp TB_MAC_TOP.vvp
gtkwave TB_MAC_TOP.vcd