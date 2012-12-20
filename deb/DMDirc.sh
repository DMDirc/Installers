#!/bin/sh
#
# This script launches dmdirc and restarts it if required.
#
# DMDirc - Open Source IRC Client
# Copyright (c) 2006-2012 DMDirc Developers
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

LAUNCHERVERSION="1"
LAUNCHERINFO="deb-${LAUNCHERVERSION}"

echo "---------------------"
echo "DMDirc - Open Source IRC Client"
echo "Launcher Version: ${LAUNCHERVERSION}"
echo "Copyright (c) 2006-2012 DMDirc Developers"
echo "---------------------"
echo "Running on Linux."
echo -n "Looking for java - ";

JAVA=`which java`

if [ "" != "${JAVA}" ]; then
	echo "Success! (${JAVA})"
else
	echo "Failed!"

	PIDOF=`which pidof`
	if [ "${PIDOF}" = "" ]; then
		# For some reason some distros hide pidof...
		if [ -e /sbin/pidof ]; then
			PIDOF=/sbin/pidof
		elif [ -e /usr/sbin/pidof ]; then
			PIDOF=/usr/sbin/pidof
		fi;
	fi;

	PGREP=`which pgrep`
	if [ "${PIDOF}" != "" ]; then
		ISKDE=`${PIDOF} -x -s kdeinit kdeinit4`
		ISGNOME=`${PIDOF} -x -s gnome-panel`
	elif [ "${PGREP}" != "" ]; then
		ISKDE=`pgrep kdeinit`
		ISGNOME=`pgrep gnome-panel`
	else
		ISKDE=`ps -Af | grep kdeinit | grep -v grep`
		ISGNOME=`ps -Af | grep gnome-panel | grep -v grep`
	fi;
	KDIALOG=`which kdialog`
	ZENITY=`which zenity`
	DIALOG=`which dialog`

	if [ "${ISKDE}" != "" -o "${ZENITY}" = "" ]; then
		USEKDIALOG="1";
	else
		USEKDIALOG="0";
	fi;

	errordialog() {
		# Send error to console.
		echo ""
		echo "-----------------------------------------------------------------------"
		echo "[Error] DMDirc: ${1}"
		echo "-----------------------------------------------------------------------"
		echo "${2}"
		echo "-----------------------------------------------------------------------"

		# if kdialog exists, and we have a display, and we are not running gnome,
		# and either we are running kde or zenity doesn't exist..
		if [ "" != "${KDIALOG}" -a "" != "${DISPLAY}" -a "" = "${ISGNOME}" -a "${USEKDIALOG}" = "1" ]; then
			echo "Dialog on Display: ${DISPLAY}"
			${KDIALOG} --title "DMDirc: ${1}" --error "${2}"
		elif [ "" != "${ZENITY}" -a "" != "${DISPLAY}" ]; then
			# Else, if zenity exists and we have a display
			echo "Dialog on Display: ${DISPLAY}"
			${ZENITY} --error --title "DMDirc: ${1}" --text "${2}"
		elif [ "" != "${DIALOG}" ]; then
			# Else, if dialog exists and we have a display
			${DIALOG} --title "[Error] DMDirc: ${1}" --msgbox "${2}" 8 40
		fi
	}

	errordialog "Unable to launch DMDirc" "DMDirc was unable to locate java, please make sure there is a java binary in your PATH."

	exit 1;
fi

echo "Running DMDirc - "

${JAVA} -ea -jar ${jar} -l ${LAUNCHERINFO} ${@}
EXITCODE=${?}
if [ ${EXITCODE} -eq 42 ]; then
	# The client says we need to update, rerun ourself before exiting.
	${0} ${@}
fi;

exit ${EXITCODE};
