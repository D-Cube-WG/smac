onerror {quit -code 1}
source "/home/hguler/git_projects/smac/vunit/vunit_out/test_output/my_lib.tb_smac_pi.test_0_cb9ff3906d141bb71d0a546677ea5a512266bb6d/modelsim/common.do"
set failed [vunit_load]
if {$failed} {quit -code 1}
set failed [vunit_run]
if {$failed} {quit -code 1}
quit -code 0
