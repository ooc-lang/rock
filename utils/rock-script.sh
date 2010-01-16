#!/bin/sh
ROCK_PATH=/path/to/rock
export OOC_DIST=/path/to/ooc
export OOC_SDK=${ROCK_PATH}/custom-sdk
${ROCK_PATH}/bin/rock $*
