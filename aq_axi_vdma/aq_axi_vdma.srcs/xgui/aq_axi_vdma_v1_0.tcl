#Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
	set Page0 [ ipgui::add_page $IPINST  -name "Page 0" -layout vertical]
	set Component_Name [ ipgui::add_param  $IPINST  -parent  $Page0  -name Component_Name ]
	set C_ADRSWIDTH [ipgui::add_param $IPINST -parent $Page0 -name C_ADRSWIDTH]
	set C_BASEADRS [ipgui::add_param $IPINST -parent $Page0 -name C_BASEADRS]
}

proc update_PARAM_VALUE.C_ADRSWIDTH { PARAM_VALUE.C_ADRSWIDTH } {
	# Procedure called to update C_ADRSWIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_ADRSWIDTH { PARAM_VALUE.C_ADRSWIDTH } {
	# Procedure called to validate C_ADRSWIDTH
	return true
}

proc update_PARAM_VALUE.C_BASEADRS { PARAM_VALUE.C_BASEADRS } {
	# Procedure called to update C_BASEADRS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_BASEADRS { PARAM_VALUE.C_BASEADRS } {
	# Procedure called to validate C_BASEADRS
	return true
}


proc update_MODELPARAM_VALUE.C_BASEADRS { MODELPARAM_VALUE.C_BASEADRS PARAM_VALUE.C_BASEADRS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_BASEADRS}] ${MODELPARAM_VALUE.C_BASEADRS}
}

proc update_MODELPARAM_VALUE.C_ADRSWIDTH { MODELPARAM_VALUE.C_ADRSWIDTH PARAM_VALUE.C_ADRSWIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_ADRSWIDTH}] ${MODELPARAM_VALUE.C_ADRSWIDTH}
}

