vsim top_optimized -coverage +UVM_TESTNAME=random_test
set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all