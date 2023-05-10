transcript file log/RUN_LOG.log

vopt tb_top -o top_optimized  +acc +cover=sbfec+openhmc_top(rtl).

vsim top_optimized -c -assertdebug -debugDB -fsmdebug -coverage +UVM_TESTNAME=hmc_init_test
set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

do waves.do

coverage report                   -output code_coverage/short.txt
coverage report -details          -output code_coverage/long.txt
coverage report -details -assert  -output code_coverage/assertions.txt

transcript file ()


#quit