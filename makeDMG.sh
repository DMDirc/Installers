#!/bin/sh
#
# This script will produce a dmg for DMDirc.
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
	echo "This will generate a DMDirc osx package."
	echo "The following command line arguments are known:"
	echo "---------------------"
	echo "-h, --help                Help information"
	echo "-j, --jar <jar>           What jar to use for the package (requires --version)"
	echo "-v, --version <version>   What version is this package."
	echo "-e, --extra <extra>       Extra tagging on output file."
	echo "---------------------"
	exit 0;
}

JAR=""
VERSION=""
finalTag=""

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
		--help|-h)
			showHelp;
			;;
		--extra|-e)
			shift
			finalTag="-${1}"
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
cd "${BASEDIR}"

# Check that we can create dmg files.
MKISOFS=`which mkisofs`
HDIUTIL=`which hdiutil`

if [ "" = "${HDIUTIL}" ]; then
	if [ "" != "${MKISOFS}" ]; then
		MKISOFS_TEST=`${MKISOFS} --help 2>&1 | grep apple`
		if [ "" = "${MKISOFS_TEST}" ]; then
			echo "This machine is unable to produce dmg images (no support from mkisofs). Aborting."
			exit 1;
		fi;
	else
		echo "This machine is unable to produce dmg images (missing mkisofs or hdiutil). Aborting."
		exit 1;
	fi;
fi;

# Go into the OS X dir and check that the jni lib exists, if not try to compile
# it (this will only work on a mac)
#
# We do this here so that we have it for future if needed rather than needing to
# do it every time.
cd osx

JNIName="libDMDirc-Apple.jnilib"

if [ ! -e "${JNIName}" ]; then
	if [ -e "/System/Library/Frameworks/JavaVM.framework/Headers" ]; then
		GCC=`which gcc`
		${GCC} -dynamiclib -framework JavaVM -framework Carbon -o ${JNIName} DMDirc-Apple.c -arch x86_64
		if [ ! -e "${JNIName}" ]; then
			echo "JNI Lib not found and failed to compile. Aborting."
			exit 1;
		fi;
	else
		echo "JNI Lib not found, unable to compile on this system. Aborting."
		exit 1;
	fi;
fi;

cd "${BASEDIR}"

WGET=`which wget`
FETCH=`which fetch`
CURL=`which curl`

getFile() {
	URL=${1}
	OUTPUT=${2}

	if [ "${WGET}" != "" ]; then
		${WGET} -O ${OUTPUT} ${URL}
	elif [ "${FETCH}" != "" ]; then
		${FETCH} -o ${OUTPUT} ${URL}
	elif [ "${CURL}" != "" ]; then
		${CURL} -o ${OUTPUT} ${URL}
	fi;
}

cd "${BASEDIR}"

# Where will we be building DMDirc today?
BUILDDIR=`mktemp -d "--tmpdir=${BASEDIR}"`
echo "Building in: '${BUILDDIR}'"

# Create required OS X directories.
APPDIR="${BUILDDIR}/DMDirc.app"
CONTENTSDIR=${APPDIR}/Contents
RESDIR=${CONTENTSDIR}/Resources
MACOSDIR=${CONTENTSDIR}/MacOS

mkdir -pv ${APPDIR}
mkdir -pv ${CONTENTSDIR}
mkdir -pv ${RESDIR}
mkdir -pv ${RESDIR}/Java
mkdir -pv ${MACOSDIR}

# Copy in required files.
cp "${JAR}" "${RESDIR}/Java/DMDirc.jar"
cp "launcher/unix/DMDirc.sh" "${MACOSDIR}/DMDirc.sh"
cp "launcher/unix/functions.sh" "${MACOSDIR}/functions.sh"
cp "osx/res/dmdirc.icns" "${RESDIR}/dmdirc.icns"
cp -v "osx/res/VolumeIcon.icns" "${DMG}/.VolumeIcon.icns"
cp -v "osx/res/Background.png" "${DMG}/.background/background.png"
cp -v "osx/.DS_Store" "${DMG}/.DS_Store"

echo "Creating meta files"
echo "APPLDMDI" > ${CONTENTSDIR}/PkgInfo

# Create the plist file
cat <<EOF> ${CONTENTSDIR}/Info.plist

<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist SYSTEM "file://localhost/System/Library/DTDs/PropertyList.dtd">
<plist version="0.9">
<dict>
	<key>CFBundleName</key>
	<string>DMDirc</string>
	<key>CFBundleIdentifier</key>
	<string>com.dmdirc.osx</string>
	<key>CFBundleAllowMixedLocalizations</key>
	<string>true</string>
	<key>CFBundleExecutable</key>
	<string>DMDirc.sh</string>
	<key>CFBundleDevelopmentRegion</key>
	<string>English</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleSignature</key>
	<string>DMDI</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleIconFile</key>
	<string>dmdirc.icns</string>
	<key>CFBundleVersion</key>
	<string>${VERSION}</string>
	<key>CFBundleShortVersionString</key>
	<string>${VERSION}</string>
	<key>Java</key>
	<dict>
		<key>WorkingDirectory</key>
		<string>\$APP_PACKAGE/Contents/Resources/Java</string>
		<key>MainClass</key>
		<string>com.dmdirc.Main</string>
		<key>JVMVersion</key>
		<string>1.6+</string>
		<key>ClassPath</key>
		<string>\$JAVAROOT/DMDirc.jar</string>
	</dict>
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleURLName</key>
			<string>IRC URL</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>irc</string>
			</array>
		</dict>
	</array>
</dict>
</plist>
EOF


# Now, make a dmg
OUTPUTFILE="DMDirc.dmg"
rm -Rf "${OUTPUTFILE}" "${OUTPUTFILE}.pre"

if [ "" = "${HDIUTIL}" ]; then
	# Create Read-Only blessed image
	${MKISOFS} -V 'DMDirc' -no-pad -r -apple -o "${OUTPUTFILE}" -hfs-creator "DMDI" -hfs-bless "/Volumes/DMDirc" "${BUILDDIR}"

	# Compres it \o
	if [ ! -e "osx/compress-dmg" ]; then
		getFile "http://binary.dmdirc.com/dmg" "osx/compress-dmg"
		chmod a+x osx/compress-dmg
	fi;
	if [ ! -e "osx/compress-dmg" ]; then
		echo "DMG will not be compressed."
	else
		echo "Compressing DMG"
		mv "${OUTPUTFILE}" "${OUTPUTFILE}.pre"
		osx/compress-dmg dmg "${OUTPUTFILE}.pre" "${OUTPUTFILE}"
		if [ -e "${OUTPUTFILE}" ]; then
			rm -Rf "${OUTPUTFILE}.pre"
		else
			echo "Compression failed."
			mv "${OUTPUTFILE}.pre" "${OUTPUTFILE}"
		fi;
	fi;
else
	# OSX
	# Create Read/Write image
	${HDIUTIL} create -volname "DMDirc" -fs HFS+ -srcfolder "${BUILDDIR}" -format UDRW "${OUTPUTFILE}.pre"
	
	# Make it auto-open
	BLESS=`which bless`
	if [ "" != "${BLESS}" ]; then
		if [ -e /Volumes/DMDirc ]; then
			${HDIUTIL} detach /Volumes/DMDirc
		fi;
		if [ ! -e /Volumes/DMDirc ]; then
			${HDIUTIL} attach "${OUTPUTFILE}.pre"
			${BLESS} -openfolder /Volumes/DMDirc
			${HDIUTIL} detach /Volumes/DMDirc
		fi;
	fi;
	# Convert to compressed read-only image
	${HDIUTIL} convert "${OUTPUTFILE}.pre" -format UDZO -imagekey zlib-level=9 -o "${OUTPUTFILE}"
	rm "${OUTPUTFILE}.pre"
fi;

if [ "${VERSION}" != "" ]; then
	DEST="DMDirc-${VERSION}${finalTag}.dmg"
else
	DEST="DMDirc${finalTag}.dmg"
fi;

mv "${OUTPUTFILE}" "output/${DEST}"

rm -Rf "${OUTPUTFILE}" "${OUTPUTFILE}.pre" "${BUILDDIR}"

echo "DMG Creation complete!"