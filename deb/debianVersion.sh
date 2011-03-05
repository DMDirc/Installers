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


debianVersion() {
	# To trick the versioning, each "unstable type" has to have a value
	# The higher the value, the more stable,
	ALPHANUM="10"
	BETANUM="20"
	RCNUM="30"

	# Parameters passed to us
	INVER="${1}"
	REVISION="${2-"1"}"
	EPOCH="${3-"0"}"

	# EXTRAVER=${INVER#*-}

	# Get the main part of the version.
	MAINVER=${INVER%%-*}

	# This is horrible (sed sucks...), but it basically splits the version number
	# out like so:
	#
	# <main version>|<milestone number>|<unstable type>|<unstable number>
	SPLITVER=`echo "${MAINVER}" | sed -e "s/^\([0-9]\+\(\.[0-9]\+\)*\)\(m\([0-9]\+\)*\)*\(\(rc\|a\|b\)\([0-9]\+\)*\)*$/\1|\4|\6|\7/g"`

	# If SPLITVER isn't valuely like what we expected, abort.
	if [ "${SPLITVER}" = "${MAINVER}" ]; then
		echo "";
		return;
	fi;

	# Now, split out the SPLITVER bits into useful bits.
	MAINVER=`echo "${SPLITVER}" | awk -F\| '{print $1}'`
	MILESTONE=`echo "${SPLITVER}" | awk -F\| '{print $2}'`
	UNSTABLETYPE=`echo "${SPLITVER}" | awk -F\| '{print $3}'`
	UNSTABLENUM=`echo "${SPLITVER}" | awk -F\| '{print $4}'`

	# If this is an integer-only version number, then we are 0.0+
	INTONLY=`echo "${INVER}" | grep "^[[:digit:]]$"`

	if [ "${INTONLY}" = "${INVER}" ]; then
		MAINVER="0.0"

	elif [ "${UNSTABLETYPE}" != "" -o "${MILESTONE}" != "" ]; then
		# If this is an unstable (or milestone) version, then we need to drop the main version
		# by .1
		LAST=${MAINVER##*.}
		SECLAST=${MAINVER%.*}
		REST=${SECLAST%.*}
		SECLAST=${SECLAST##*.}

		LAST=$(($LAST - 1))

		if [ ${LAST} -lt 0 ]; then
			LAST=9;
			SECLAST=$(($SECLAST - 1))
		fi;

		MAINVER=${REST}.${SECLAST}.${LAST};
	fi;

	# Now we start to build a version.

	# Start with the main version.
	OUTVER="${MAINVER}+"

	# Now, if we are unstable, add bits to allow for proper versioning.
	if [ "${UNSTABLETYPE}" = "a" ]; then
		OUTVER="${OUTVER}${ALPHANUM}-"
	elif [ "${UNSTABLETYPE}" = "b" ]; then
		OUTVER="${OUTVER}${BETANUM}-"
	elif [ "${UNSTABLETYPE}" = "rc" ]; then
		OUTVER="${OUTVER}${RCNUM}-"
	fi;

	# And now add the full version again.
	OUTVER="${OUTVER}${INVER}"

	# Special Case.
	if [ "${OUTVER}" = "${INVER}+${INVER}" ]; then
		OUTVER="${INVER}"
	fi;

	# If an epoch was given, use it.
	if [ "${EPOCH}" != "" -a "${EPOCH}" != "0" ]; then
		OUTVER="${EPOCH}:${OUTVER}"
	fi;

	# Output
	echo "${OUTVER}-${REVISION}"
}