##############################################################################
## Michael Steffen
## Joseph Zambreno
## tb_SGP.udo - User do file for simulating the SGP graphics processor design
##############################################################################


#vlog  +incdir+. +define+x512Mb +define+sg37E +define+x16 ../sim/ddr2_model.v


#Change radix to Hexadecimal#
radix hex

# Supress Numeric Std package and Arith package warnings.
# For VHDL designs we get some warnings due to unknown values on some signals at startup
# ** Warning: NUMERIC_STD.TO_INTEGER: metavalue detected, returning 0
# We may also get some Arithmetic packeage warnings because of unknown values on
# some of the signals that are used in an Arithmetic operation.
# In order to suppress these warnings, we use following two commands
set NumericStdNoWarnings 1
set StdArithNoWarnings 1


# Choose simulation run time by inserting a breakpoint and then run for specified 
# period. For more details, refer to Simulation Guide section of MIG user guide (UG086).
when {/tb_SGP/u_SGP/u_system/ddr2_done = 1} {
if {[when -label a_100] == ""} {
when -label a_100 { $now = 40 ms } {
nowhen a_100
report simulator control
report simulator state
}
}
}


# In case calibration fails to complete, choose the run time and then stop
when {$now = @500 us and /tb_SGP/u_SGP/u_system/ddr2_done != 1} {
echo "TEST FAILED: CALIBRATION DID NOT COMPLETE"
stop
}

force -freeze sim:/tb_sgp/u_sgp/u_system/u_memInit/init_done 1 0
force -freeze sim:/tb_sgp/u_sgp/u_system/u_dispInterface/tft_cont/u_tft_interface/gen_dvi_if/iic_init/Done 1 0


run 400ns


