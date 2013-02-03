######################################################################
# Joseph Zambreno
# setup.sh - shell configuration for CprE480x labs
######################################################################

# Confirm that you have not already run the setup.sh
if [ "$SGP_SETUP" == "1" ]; then
  printf "Error: SGP_SETUP already defined.\n"
  printf "Please open a new terminal to apply new changes, or set the SGP_\n"
  printf "configuration variables directly.\n"
  return 1
fi

export SGP_SETUP="1"


# Link-time driver configuration variables. 
# Check the CprE 480X documentation for how to change these. 
export SGP_TRANSMIT="ETH"         # [UART | ETH | NONE*]
export SGP_TRACE="FILE"            # [FILE | STDOUT | VBIOS | NONE*]
export SGP_PORT="192.168.1.12"       # [/dev/ttyS0* | 192.168.1.12]
export SGP_NAME="trace.sgb"        # [trace.sgb*]

alias sgpUART="export SGP_TRANSMIT=UART;export SGP_PORT=/dev/ttyS0;"
alias sgpETH="export SGP_TRANSMIT=ETH;export SGP_PORT=192.168.1.12;"
alias sgpNONE="export SGP_TRANSMIT=NONE;export SGP_TRACE=NONE;"
alias sgpNOLOG="export SGP_TRACE=NONE"
alias sgpLOG="export SGP_TRACE=FILE"
alias sgpLIST="export | grep SGP"

# Xilinx / Modelsim version numbers. No need to change these
export XLNX_VER=12.2
export ARCH_VER=64
export VSIM_VER=6.5c


SDIR=`dirname "$BASH_SOURCE"`
export CDIR=`readlink -f "$SDIR"`


printf "Setting up environment variables for %s-bit Xilinx tools, version %s..." $ARCH_VER $XLNX_VER 
source /remote/Xilinx/$XLNX_VER/settings$ARCH_VER.sh
printf "done.\n"

printf "Setting up path for %s-bit Modelsim tools, version %s..." $ARCH_VER $VSIM_VER
export PATH=$PATH:/remote/Modelsim/$VSIM_VER/modeltech/linux_x86_64/
printf "done.\n"

printf "Setting up license file..."
export LM_LICENSE_FILE=1717@io.ece.iastate.edu:27006@io.ece.iastate.edu
printf "done.\n"

printf "Adding CprE 480x utils/ to your path..."
export PATH=$PATH:$CDIR/utils/bin/:$CDIR/sw/bin/
export LD_LIBRARY_PATH=$CDIR/utils/lib64:$CDIR/utils/lib:$CDIR/sw/common/lib:$LD_LIBRARY_PATH
printf "done.\n"


