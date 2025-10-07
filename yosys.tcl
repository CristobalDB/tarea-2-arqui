yosys -import

# Lee SOLO el RTL del computador (sin testbench)
read_verilog -sv alu.v pc.v register.v instruction_memory.v control_unit.v computer.v

# Define top y verifica jerarquía
hierarchy -check -top computer

# Síntesis y reporte
synth -top computer
stat

# Netlist a disco
write_verilog -noattr out/netlist.v



