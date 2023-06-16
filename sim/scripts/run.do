#***************************************************#
# Clean Work Library
#***************************************************#
if [file exists "work"] {vdel -all}
vlib work

#***************************************************#
# Start a new Transcript File
#***************************************************#
transcript file log/RUN_LOG.log

#***************************************************#
# Compile RTL and TB files
#***************************************************#
vlog -f scripts/dut.f
vlog -f scripts/tb.f

#***************************************************#
# Optimizing Design with vopt
#***************************************************#
vopt tb_top -o top_opt -debugdb  +acc +cover=sbecf+openhmc_top(rtl).

#***************************************************#
# Simulation of a Test
#***************************************************#
#************************************** 1. HMC INITIALIZATION TEST ***********************************#
vsim top_opt -c -assertdebug -debugDB -fsmdebug -coverage +UVM_TESTNAME=hmc_init_test
set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

#***************************************************#
# Save Coverage in a .ucdb file
#***************************************************#
coverage attribute -name TESTNAME -value hmc_init_test
coverage save coverage/hmc_init_test.ucdb

#************************************** 2. RF RESET TEST ***********************************#
vsim top_opt -c -assertdebug -debugDB -fsmdebug -coverage +UVM_TESTNAME=rf_reset_test
set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all
coverage attribute -name TESTNAME -value rf_reset_test
coverage save coverage/rf_reset_test.ucdb

#************************************** 3. AXI TEST ***********************************#
vsim top_opt -c -assertdebug -debugDB -fsmdebug -coverage +UVM_TESTNAME=axi_test
set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all
coverage attribute -name TESTNAME -value axi_test
coverage save coverage/axi_test.ucdb


#***************************************************#
# draw the dut pins in waveforms
#***************************************************#
do waves.do

#***************************************************#
# save the coverage in text files
#***************************************************#
vcover merge  coverage/openhmc.ucdb \
              coverage/axi_test.ucdb \
              coverage/hmc_init_test.ucdb \
              coverage/rf_reset_test.ucdb
              
vcover report coverage/openhmc.ucdb -cvg -details -output coverage/fun_coverage.txt
vcover report coverage/openhmc.ucdb -details -assert  -output coverage/assertions.txt
vcover report coverage/openhmc.ucdb  -output coverage/code_coverage.txt


#***************************************************#
# Close the Transcript file
#***************************************************#
transcript file ()

#add schematic -full sim:/tb_top/dut
#quit -sim