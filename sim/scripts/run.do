#***************************************************#
# Clean Work Library
#***************************************************#
if [file exists "work"] {vdel -all}
vlib work

#***************************************************#
# Start a new Transcript File
#***************************************************#
transcript file log/RUN_LOG.log
# better make one for each test

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
transcript file log/simple_test.log
vsim top_opt -c -assertdebug -debugDB -fsmdebug -coverage +UVM_TESTNAME=simple_test
set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all
coverage attribute -name TESTNAME -value simple_test
coverage save coverage/simple_test.ucdb

#********************************** 2. Read Only TEST ***********************************#
transcript file log/read_only_test.log
vsim top_opt -c -assertdebug -debugDB -fsmdebug -coverage +UVM_TESTNAME=read_only_test
set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all
coverage attribute -name TESTNAME -value read_only_test
coverage save coverage/read_only_test.ucdb

#********************************** 3. Posted Only TEST ***********************************#
transcript file log/posted_only_test.log
vsim top_opt -c -assertdebug -debugDB -fsmdebug -coverage +UVM_TESTNAME=posted_only_test
set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all
coverage attribute -name TESTNAME -value posted_only_test
coverage save coverage/posted_only_test.ucdb

#********************************** 4. Write Only TEST ***********************************#
transcript file log/write_only_test.log
vsim top_opt -c -assertdebug -debugDB -fsmdebug -coverage +UVM_TESTNAME=write_only_test
set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all
coverage attribute -name TESTNAME -value write_only_test
coverage save coverage/write_only_test.ucdb

#********************************** 4. RESET TESTS ***********************************#
do scripts/reset_tests.do

#***************************************************#
# Close the Transcript file
#***************************************************#
transcript file ()

#***************************************************#
# draw the dut pins in waveforms
#***************************************************#
#do waves.do

#***************************************************#
# save the coverage in text files
#***************************************************#
vcover merge  coverage/openhmc.ucdb \
              coverage/simple_test.ucdb \
              coverage/read_only_test.ucdb \
              coverage/posted_only_test.ucdb \
              coverage/write_only_test.ucdb \
              coverage/reset_tests.ucdb
              
              
              
vcover report coverage/openhmc.ucdb -cvg -details -output coverage/fun_coverage.txt
vcover report coverage/openhmc.ucdb -details -assert  -output coverage/assertions.txt
vcover report coverage/openhmc.ucdb  -output coverage/code_coverage.txt


#add schematic -full sim:/tb_top/dut
#quit -sim