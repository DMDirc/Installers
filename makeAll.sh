#!/bin/sh
#
# This script will produce all the DMDirc packages
#
# DMDirc - Open Source IRC Client
# Copyright (c) 2006-2011 Chris Smith, Shane Mc Cormack, Gregory Holmes
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
	echo "-e, --extra <extra>       Extra tagging on output file."
	echo "-c, --channel <channel>   Channel to pass to ant (if not passed, 'NONE', if passed without a value, 'STABLE')"
	echo "                          (only applicable when building a fresh jar)"
	echo "    --upload              Upload output files to google code."
	echo "---------------------"
	exit 0;
}

JAR=""
VERSION=""
finalTag=""
UPLOAD="0"
CHANNEL="NONE"
while test -n "$1"; do
	case "$1" in
		--jar|-j)
			shift
			JAR="${1}"
			;;
		--version|-v)
			shift
			VERSION="${1}"
			;;
		--help|-h)
			showHelp;
			;;
		--extra|-e)
			shift
			finalTag="${1}"
			;;
		--upload)
			UPLOAD="1"
			;;
		--channel|-c)
			PASSEDPARAM=`echo "${2}" | grep -v ^- | grep -v " "`
			if [ "${PASSEDPARAM}" != "" ]; then
				shift
				CHANNEL="${PASSEDPARAM}";
			else
				CHANNEL="STABLE";
			fi;
			;;
	esac
	shift
done

# Directory to clone DMDirc to if needed.
BUILDDIR=""

# Find out where we are
BASEDIR=$(cd "${0%/*}" 2>/dev/null; echo $PWD)
cd "${BASEDIR}"

OUTPUT="${BASEDIR}/output"
rm -Rf "${OUTPUT}"
mkdir -p ${OUTPUT}

if [ "${JAR}" != "" -a "${VERSION}" = "" ]; then
	echo "When providing a jar, you must also provide a version."
	echo ""
	echo "Providing neither will make a fresh checkout of the current source and"
	echo "build that."
	exit 1;
fi;

# Final name for the jar.
# The given (or compiled) jar will be copied here, and then the build scripts
# will be given this file name to build from.

if [ "${JAR}" = "" -o ! -e "${JAR}" ]; then
	echo "No jar given, or jar does not exist. Building."

	# By default the source is located 2 directories above us.
	SOURCEDIR="../../";

	# Do we have a valid source directory above us?
	if [ ! -e "${SOURCEDIR}/.git" -o ! -e "${SOURCEDIR}/build.xml" ]; then
		# If not, lets create one here to use.
		BUILDDIR=`mktemp -d "--tmpdir=${BASEDIR}"`

		git clone git://dmdirc.com/client "${BUILDDIR}"

		cd "${BUILDDIR}"
		git submodule init
		git submodule update

		cd "${BASEDIR}"
		SOURCEDIR="${BUILDDIR}"
	fi;

	# Do we have a valid source directory to build in now?
	if [ -e "${SOURCEDIR}/.git" -a -e "${SOURCEDIR}/build.xml" ]; then
		cd ${SOURCEDIR};
		VERSION=`git describe --tags --always`

		ant -Dchannel=${CHANNEL} clean jar

		if [ ! -e "dist/DMDirc.jar" ]; then
			echo "Unable to build DMDirc.jar, aborting."
			cd "${BASEDIR}"
			if [ "${BUILDDIR}" != "" ]; then
				rm -Rfv "${BUILDDIR}"
			fi;
			exit 1;
		fi
	else
		echo "Unable to build DMDirc.jar, aborting."
		cd "${BASEDIR}"
		if [ "${BUILDDIR}" != "" ]; then
			rm -Rfv "${BUILDDIR}"
		fi;
		exit 1;
	fi;

	# Return to base dir after building.
	cd "${BASEDIR}"
	
	# Copy the DMDirc.jar to the final location
	cp "${SOURCEDIR}/dist/DMDirc.jar" "${OUTPUT}/DMDirc.jar"
	if [ "${BUILDDIR}" != "" ]; then
		rm -Rfv "${BUILDDIR}"
	fi;
else
	cp "${JAR}" "${OUTPUT}/DMDirc.jar"
fi;

if [ "${finalTag}" != "" ]; then
	FINALNAME="DMDirc-${VERSION}-${finalTag}.jar"
else
	FINALNAME="DMDirc-${VERSION}.jar"
fi;

mv "${OUTPUT}/DMDirc.jar" "${OUTPUT}/${FINALNAME}"

JAR="${OUTPUT}/${FINALNAME}"

if [ "${finalTag}" != "" ]; then
	EXTRAARGS=" --extra \"${finalTag}\""
fi;

echo "================================================================"
echo "Making Deb"
echo "================================================================"
./makeDEB.sh --jar "${JAR}" --version "${VERSION}"${EXTRAARGS}
echo "================================================================"

echo "================================================================"
echo "Making EXE"
echo "================================================================"
./makeNSIS.sh --jar "${JAR}" --version "${VERSION}"${EXTRAARGS}
echo "================================================================"

echo "================================================================"
echo "Making DMG"
echo "================================================================"
./makeDMG.sh --jar "${JAR}" --version "${VERSION}"${EXTRAARGS}
echo "================================================================"


echo "================================================================"
echo "Creating Stop-Gap Packages"
echo "================================================================"
# Use alien to create rpm and tgz packages from the deb package.
# These need to be changed in future to create independantly on their own
# When we understand these package formats more.
ALIEN=`which alien`
FAKEROOT=`which fakeroot`
if [ "${ALIEN}" != "" -a "${FAKEROOT}" != "" ]; then
	CURDIR=`pwd`
	cd ${OUTPUT}

	# Theres no point passing --scripts here as the scripts expect debian
	# parameters. which won't be given.
	#
	# The scripts only make us a protocol handler for irc, so missing them
	# isn't really a huge issue.
	${FAKEROOT} ${ALIEN} --to-rpm DMDirc-${VERSION}.deb
	${FAKEROOT} ${ALIEN} --to-tgz DMDirc-${VERSION}.deb

	mv dmdirc-*.rpm DMDirc-${VERSION}.rpm
	mv dmdirc-*.tgz DMDirc-${VERSION}.tgz
	
	cd ${CURDIR}
fi;
echo "================================================================"

echo "Done."

if [ "${UPLOAD}" = "1" ]; then
	echo "================================================================"
	echo "Uploading to GoogleCode"
	echo "================================================================"

	cd gcode
	sh uploads_release.sh -v ${VERSION}
fi;

exit 0;