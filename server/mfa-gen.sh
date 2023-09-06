#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd -P)"

Password=${ENV_PIN}
SecuritToken=${ENV_OTPToken}
OTPCode=`${SCRIPT_DIR}/otpgen.py ${SecuritToken}`

echo "MFA Code : ${OTPCode}"