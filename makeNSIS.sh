#!/bin/sh
#
# This script will produce an installer/launcher exe for DMDirc.
#
# DMDirc - Open Source IRC Client
# Copyright (c) 2006-2014 DMDirc Developers
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

showHelp() {
	echo "This will generate a DMDirc debian package."
	echo "The following command line arguments are known:"
	echo "---------------------"
	echo "-h, --help                Help information"
	echo "-j, --jar <jar>           What jar to use for the package (requires --version)"
	echo "-v, --version <version>   What version is this package."
	echo "-u, --unsigned            Don't sign the output"
	echo "-p, --packagename <name>  Name for output (rather than DMDirc-<version>"
	echo "-e, --extra <extra>       Extra tagging on output file."
	echo "---------------------"
	exit 0;
}

JAR=""
VERSION=""
signEXE="true"
finalTag=""
PACKAGENAME=""
while test -n "$1"; do
	case "$1" in
		--jar)
			shift
			JAR=${1}
			;;
		--version|-v)
			shift
			VERSION=${1}
			;;
		--unsigned|-u)
			signEXE="false"
			;;
		--extra|-e)
			shift
			finalTag="${1}"
			;;
		--packagename|-p)
			shift
			PACKAGENAME="${1}"
			;;
		--help|-h)
			showHelp;
			;;
	esac
	shift
done

if [ "${JAR}" = "" -o "${VERSION}" = "" -o ! -e "${JAR}" ]; then
	echo "You must provide a jar file and a version number to continue."
	exit 1;
fi;

# Find out where we are
BASEDIR=$(cd "${0%/*}" 2>/dev/null; echo $PWD)
cd ${BASEDIR}

OLDDIR=`pwd`

# Create required directories
mkdir -p output
rm -Rfv windows/files
mkdir -p windows/files

# Copy in the jar file.
cp "${JAR}" "windows/files/DMDirc.jar"
cd windows/files

# Copy the icon
cp ../../../../src/com/dmdirc/res/icon.ico icon.ico

cd ..

# Build the installers
for NSI in updater.nsi launcher.nsi installer.nsi; do
	LASTCOMMIT=`git rev-list --max-count=1 HEAD -- $NSI`
	NSISVERSION=`git describe --tags --always $LASTCOMMIT`
	makensis -DVERSION="${NSISVERSION}" -V2 $NSI;
done

# Create the output file.
# This will rename it if required.
cd "${OLDDIR}"
SRC="output/DMDirc-Setup.exe"

if [ "${PACKAGENAME}" = "" ]; then
	DEST="DMDirc-Setup-${VERSION}"
else
	DEST="${PACKAGENAME}"
fi
if [ "${finalTag}" != "" ]; then
	DEST="${DEST}-${finalTag}"
fi;
DEST="${DEST}.exe"

mv "${SRC}" "output/${DEST}"

# Get signcode path
SIGNCODE=`which signcode`

if [ "" = "${SIGNCODE}" ]; then
	echo "Signcode not found. EXE's will not be digitally signed."
fi

# Sign stuff!
signexe() {
	if [ "" != "${SIGNCODE}" ]; then
		if [ -e "signing/DMDirc.spc" -a -e "signing/DMDirc.pvk" ]; then
			echo "Digitally Signing EXE (${@})..."
			${SIGNCODE} -spc "signing/DMDirc.spc" -v "signing/DMDirc.pvk" -i "http://www.dmdirc.com/" -n "DMDirc Installer" $@ 2>/dev/null || {
				kill -15 $$;
			};
			rm ${@}.sig
			rm ${@}.bak
		else
			echo "No signing keys (signing/DMDirc.spc and signing/DMDirc.pvk) found."
		fi
	fi
}

FULLINSTALLER="output/${DEST}"

echo "Chmodding.."
chmod a+x ${FULLINSTALLER}
if [ "${signEXE}" = "true" ]; then
	echo "Signing.."
	signexe ${FULLINSTALLER}
else
	echo "Not Signing.."
fi;
