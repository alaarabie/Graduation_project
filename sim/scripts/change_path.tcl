# to run:
#1. open Tclsh86
#2. cd current path
#3. source change_path.tcl

puts "\n"
#Title
puts "**** Change Files Path ****"

#open the file
set fh [open dut.f r+]

#read the data of the file
set dut [read $fh]
puts "\nold file:\n"
puts $dut

#create a second file 
set fhnew [open dut_new.f w+]

#substitule path
regsub -all "D:/Ali/College/" $dut "Write New Path Here" dut

#print file content
puts "\nnew file:\n"
puts $dut
puts $fhnew $dut

#closing the files
close $fh
close $fhnew
#**************************************************************#
#**************************************************************#
puts "\n"
#open the file
set fh [open tb.f r+]

#read the data of the file
set tb [read $fh]
puts "\nold file:\n"
puts $tb

#create a second file 
set fhnew [open tb_new.f w+]

#substitule path
regsub -all "D:/Ali/College/" $tb "Write New Path Here" tb


#print file content
puts "\nnew file:\n"
puts $tb
puts $fhnew $tb

#closing the files
close $fh
close $fhnew