onerror {quit -code 1}
source "/home/hguler/vunit_projects/smac/vunit/vunit_out/test_output/my_lib.tb_smac.test_0_50eab1c9cc20e7c5ee9daecb8489175abda8e0c8/modelsim/common.do"
set failed [vunit_load]
if {$failed} {quit -code 1}
set failed [vunit_run]
if {$failed} {quit -code 1}
quit -code 0
