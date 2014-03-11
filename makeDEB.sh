#!/bin/sh
#
# This script will produce a deb for DMDirc.
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
	echo "    --runtests            If building from source, also run tests and javadoc"
	echo "---------------------"
	exit 0;
}

JAR=""
VERSION=""
SIGNED="true"
TESTSANDJAVADOC="0"
finalTag=""
PACKAGENAME=""
while test -n "$1"; do
	case "$1" in
		--jar|-j)
			shift
			JAR=${1}
			;;
		--version|-v)
			shift
			VERSION=${1}
			;;
		--unsigned|-u)
			SIGNED="false"
			;;
		--runtests)
			TESTSANDJAVADOC="1"
			;;
		--help|-h)
			showHelp;
			;;
		--packagename|-p)
			shift
			PACKAGENAME="${1}"
			;;
		--extra|-e)
			shift
			finalTag="${1}"
			;;
	esac
	shift
done


if [ "${JAR}" != "" -a "${VERSION}" = "" ]; then
	echo "When providing a jar, you must also provide a version."
	echo ""
	echo "Providing neither will make a fresh checkout of the current source and"
	echo "build that. (Used to produce debian-uploadable packages)"
	exit 1;
fi;

# Debian package revision
DEBIANREVISION=1

# Debian package epoch
DEBIANEPOCH=0

# Find out where we are
BASEDIR=$(cd "${0%/*}" 2>/dev/null; echo $PWD)
cd ${BASEDIR}

# "debian" directory
DEBDIR=${BASEDIR}/deb

# Where will we be building DMDirc today?
BUILDDIR=`mktemp -d "--tmpdir=${BASEDIR}"`

echo "Building in: '${BUILDDIR}'"

# Options to pass to DPKG.
DPKGOPTS=""

# If we are not given a jar to use, then we produce a full-source build.
# This will produce files ready for upload to debian.
if [ "${JAR}" = "" -o ! -e "${JAR}" ]; then
	# Clone a copy of the repo to the temp dir
	git clone git://dmdirc.com/client "${BUILDDIR}"
	
	# Change into the temp dir
	cd "${BUILDDIR}"
	
	# Init the submodules
	git submodule init
	git submodule update

	# What version of the client is this?
	VERSION=`git describe --tags --always`
else
	cp "${JAR}" "${BUILDDIR}/DMDirc.jar"
  
	# Change into the temp dir
	cd "${BUILDDIR}"

	# Modify the version.config for debian-ness
	jar -xf DMDirc.jar com/dmdirc/version.config
	cat <<EOF >>com/dmdirc/version.config
	
version:
    noupdates=true
EOF
	# Update the version in the jar
	jar uf DMDirc.jar com/dmdirc/version.config;
	rm -Rf com

	# Create a simple build.xml that will satisfy dpkg-buildpackage
	cat <<EOF >build.xml
<?xml version="1.0" encoding="UTF-8"?>
<project name="DMDirc" default="default" basedir=".">
	<description>Builds a pre-built DMDirc!</description>

	<target description="Clean project." name="clean">
		<delete dir="dist" />
	</target>

	<target description="Do Nothing" name="with.disabled.updater" />

	<target description="Build project." name="default" depends="jar" />

	<target description="Build project." name="jar">
		<copy file="DMDirc.jar" tofile="dist/DMDirc.jar" overwrite="true" />
	</target>
</project>
EOF

	DPKGOPTS=" -A"
fi;

# Copy in the debian rules
mkdir -p "${BUILDDIR}/debian"
cp -Rfv "${DEBDIR}/"* .
cp -Rfv ../res/logo.svg icon.svg

# Include function for creating Debain Versions
. "${DEBDIR}/debianVersion.sh";

# Create a Debain Version from the DMDirc version.
DEBIANVERSION=$(debianVersion "${VERSION}" "${DEBIANREVISION}" "${DEBIANEPOCH}")

# What time is this build happening?
BUILDTIME=`date -R`

# Change the changelog to be a default one.
cat <<EOF >debian/changelog
dmdirc (${DEBIANVERSION}) unstable; urgency=low

  * Debian Package for DMDirc ${VERSION}, for changes see: http://git.dmdirc.com/
  * This changelog will be better in future, honest!

 -- DMDirc Developers <devs-public@dmdirc.com>  ${BUILDTIME}
EOF

# And build
if [ "${SIGNED}" != "true" ]; then
	DPKGOPTS=" -uc -us"
fi;

dpkg-buildpackage ${DPKGOPTS}

# Move the resulting files to the output directory.
cd "${BASEDIR}"
mkdir -p "output/debian"
mv "dmdirc_${DEBIANVERSION}"*.* "output/debian"

# Copy the files we actually care about into the output directory
SRC=`ls -1 "output/debian/dmdirc_${DEBIANVERSION}"*".deb"`

if [ "${PACKAGENAME}" = "" ]; then
	DEST="DMDirc-${VERSION}"
else
	DEST="${PACKAGENAME}"
fi
if [ "${finalTag}" != "" ]; then
	DEST="${DEST}-${finalTag}"
fi;
DEST="${DEST}.deb"

cp -v "${SRC}" "output/${DEST}"

# Clean Up
rm -Rf "${BUILDDIR}"
