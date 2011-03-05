#!/bin/sh
#
# This function will take a DMDirc git tag, and turn it into a
# debian-compatible version such that version ordering is
# maintained.
#
# See: http://people.debian.org/~calvin/unofficial/
#
# This appears to work ok.
#
# DMDirc - Open Source IRC Client
# Copyright (c) 2006-2011 DMDirc Developers
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Find out where we are
BASEDIR=$(cd "${0%/*}" 2>/dev/null; echo $PWD)
. ${BASEDIR}/../debianVersion.sh;

TESTCOUNT=0
FAILCOUNT=0

testVersion() {
	TYPE=${3-"lt"}
	dpkg --compare-versions "${1}" "${TYPE}" "${2}";
	RES=${?}
	if [ ${RES} = 0 ]; then
		echo "${1} ${TYPE} ${2} [CORRECT]";
	else
		echo "${1} ${TYPE} ${2} [WRONG]";
		FAILCOUNT=$((${FAILCOUNT} + 1))
	fi;

	TESTCOUNT=$((${TESTCOUNT} + 1))
}


testVersion $(debianVersion "1") $(debianVersion "2") "lt"
testVersion $(debianVersion "1") $(debianVersion "2000") "lt"
testVersion $(debianVersion "2") $(debianVersion "1") "gt"
testVersion $(debianVersion "1") $(debianVersion "1") "eq"
testVersion $(debianVersion "0") $(debianVersion "0") "eq"
testVersion $(debianVersion "1") $(debianVersion "0.6") "lt"
testVersion $(debianVersion "0.6") $(debianVersion "0.6") "eq"
testVersion $(debianVersion "0.6") $(debianVersion "0.6.3") "lt"
testVersion $(debianVersion "0.6-149-gaaaaaaa") $(debianVersion "0.6.3") "lt"
testVersion $(debianVersion "0.6-149-gaaaaaaa") $(debianVersion "0.6.3-149-gaaaaaaa") "lt"
testVersion $(debianVersion "0.6.3") $(debianVersion "0.6.3-149-gaaaaaaa") "lt"
testVersion $(debianVersion "0.6.3a1") $(debianVersion "0.6.3") "lt"
testVersion $(debianVersion "0.6.3b1") $(debianVersion "0.6.3") "lt"
testVersion $(debianVersion "0.6.3rc1") $(debianVersion "0.6.3") "lt"
testVersion $(debianVersion "0.6.3m1") $(debianVersion "0.6.3") "lt"
testVersion $(debianVersion "0.6.3m1b1") $(debianVersion "0.6.3") "lt"
testVersion $(debianVersion "0.6.3m1a1") $(debianVersion "0.6.3m1b1") "lt"
testVersion $(debianVersion "0.6.3m1a1") $(debianVersion "0.6.3m1a1-149-gaaaaaaa") "lt"
testVersion $(debianVersion "0.6.3-148-gaaaaaaa") $(debianVersion "0.6.3-149-gaaaaaaa") "lt"
testVersion $(debianVersion "0.6.3-148-gaaaaaaa") $(debianVersion "0.6.3-148-gaaaaaaa") "eq"
testVersion $(debianVersion "0.6.3-148-gaaaaaaa" "10" "1") $(debianVersion "0.6.3-148-gaaaaaaa" "1" "2") "lt"

echo "";
echo "Result:";
echo "\tRun: ${TESTCOUNT}";
echo "\tFailed: ${FAILCOUNT}";
