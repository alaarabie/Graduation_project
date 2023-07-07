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

#********************************** 1. Simple TEST ***********************************#
vsim top_opt -c -assertdebug -debugDB -fsmdebug -coverage +UVM_TESTNAME=reset4_test
set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all
coverage attribute -name TESTNAME -value reset4_test
coverage save coverage/reset4_test.ucdb


#***************************************************#
# draw the dut pins in waveforms
#***************************************************#
do waves.do

#***************************************************#
# save the coverage in text files
#***************************************************#

#***************************************************#
# Close the Transcript file
#***************************************************#
transcript file ()

#add schematic -full sim:/tb_top/dut
#quit -sim