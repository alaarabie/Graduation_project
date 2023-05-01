#if [file exists "work"] {vdel -all}
#vlib work


#vlog -f tb.f
#vopt tb_top -o top_optimized  +acc +cover=sbfec+openhmc_top(rtl).

#vsim top_optimized -coverage +UVM_TESTNAME=random_test
set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all


#quit
