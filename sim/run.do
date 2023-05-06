transcript file log/RUN_LOG.log

vopt tb_top -o top_optimized  +acc +cover=sbfec+openhmc_top(rtl).

#vsim -assertdebug -coverage -c -voptargs=+acc work.ATM_tb \
#-do "add wave -position insertpoint sim:/ATM_tb/*; run -all; coverage report -codeAll -cvg -verbose"

vsim top_optimized -assertdebug -coverage +UVM_TESTNAME=random_test
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