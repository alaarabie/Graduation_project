#********************************** Run All Reset Tests ***********************************#
transcript file log/reset1_test.log
vsim top_opt -c -assertdebug -debugDB -fsmdebug -coverage +UVM_TESTNAME=reset1_test
set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all
coverage attribute -name TESTNAME -value reset1_test
coverage save coverage/reset1_test.ucdb

transcript file log/reset2_test.log
vsim top_opt -c -assertdebug -debugDB -fsmdebug -coverage +UVM_TESTNAME=reset2_test
set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all
coverage attribute -name TESTNAME -value reset2_test
coverage save coverage/reset2_test.ucdb

transcript file log/reset3_test.log
vsim top_opt -c -assertdebug -debugDB -fsmdebug -coverage +UVM_TESTNAME=reset3_test
set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all
coverage attribute -name TESTNAME -value reset3_test
coverage save coverage/reset3_test.ucdb

transcript file log/reset4_test.log
vsim top_opt -c -assertdebug -debugDB -fsmdebug -coverage +UVM_TESTNAME=reset4_test
set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all
coverage attribute -name TESTNAME -value reset4_test
coverage save coverage/reset4_test.ucdb

transcript file log/reset5_test.log
vsim top_opt -c -assertdebug -debugDB -fsmdebug -coverage +UVM_TESTNAME=reset5_test
set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all
coverage attribute -name TESTNAME -value reset5_test
coverage save coverage/reset5_test.ucdb

#***************************************************#
# Close the Transcript file
#***************************************************#
transcript file ()

#***************************************************#
# save the coverage in text files
#***************************************************#
vcover merge  coverage/reset_tests.ucdb \
              coverage/reset1_test.ucdb \
              coverage/reset2_test.ucdb \
              coverage/reset3_test.ucdb \
              coverage/reset4_test.ucdb \
              coverage/reset5_test.ucdb