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
vopt tb_top -o top_optimized -debugdb  +acc +cover=sbfec+openhmc_top(rtl).

#***************************************************#
# Simulation of a Test
#***************************************************#
vsim top_optimized -c -assertdebug -debugDB -fsmdebug -coverage +UVM_TESTNAME=rf_reset_test
set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

#***************************************************#
# Save Functional Coverage in a .ucdb file
#***************************************************#
coverage attribute -name TESTNAME -value rf_reset_test
coverage save functional_coverage/rf_reset_test.ucdb

#***************************************************#
# draw the dut pins in waveforms
#***************************************************#
do waves.do

#***************************************************#
# save the functional coverage in a text file
#***************************************************#
vcover report functional_coverage/rf_reset_test.ucdb -cvg -details -output functional_coverage/coverage.txt

#***************************************************#
# save code coverage in text files
#***************************************************#
coverage report                   -output code_coverage/short.txt
coverage report -details          -output code_coverage/long.txt
coverage report -details -assert  -output code_coverage/assertions.txt

#***************************************************#
# Close the Transcript file
#***************************************************#
transcript file ()

#add schematic -full sim:/tb_top/dut
#quit