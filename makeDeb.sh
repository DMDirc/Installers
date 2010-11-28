#!/bin/sh

# Are we building a nightly, or a real package?
NIGHTLY=1

# Should we do test/javadoc?
TESTSANDJAVADOC=0

# Find out where we are
BASEDIR=$(cd "${0%/*}" 2>/dev/null; echo $PWD)
cd ${BASEDIR}

# "debian" directory
DEBDIR=${BASEDIR}/deb/debian

# Where will we be building DMDirc today?
BUILDDIR=`mktemp -d --tmpdir=${BASEDIR}`

# Clone a copy of the repo to the temp dir
git clone git://dmdirc.com/client ${BUILDDIR}

# Change into the temp dir
cd ${BUILDDIR}

# Init the submodules
git submodule init
git submodule update

# Copy in the debian rules
cp -Rf ${DEBDIR} .

# What version of the client is this?
# I'm not sure if debian can handle this as a version.
VERSION=`git describe --tags --always`

# Debian package version
DEBIANVERSION=1

# Final Version Number
FINALVERSION=${VERSION}-${DEBIANVERSION}

if [ "${NIGHTLY}" = "1" ]; then
  NIGHTLYDATE=`date -R`
  UPDATETIME=`git log -1 --format=format:%ct`

  FINALVERSION="nightly-${UPDATETIME}-${DEBIANVERSION}"

  # Change the changelog to be a default one for nightlies.
  cat <<EOF >debian/changelog
dmdirc (nightly-${UPDATETIME}-${DEBIANVERSION}) unstable; urgency=low

  * Nightly Build (${VERSION}), for changes see: http://git.dmdirc.com/

 -- DMDirc Developers <devs-public@dmdirc.com>  ${NIGHTLYDATE}
EOF
fi;
# Otherwise, we need to make a proper changelog somehow.
#
# And also a real version number. Our normal scheme isn't qutie compatible :/
# http://people.debian.org/~calvin/unofficial/

# Development netbook is slow, so this helps speed things up when testing.
if [ "${TESTSANDJAVADOC}" = "0" ]; then
  sed -i 's@<target depends="test,jar,javadoc" description="Build and test whole project." name="default"/>@<target depends="jar" description="Build and test whole project." name="default"/>@' nbproject/build-impl.xml
fi

# Remove the .git dir as we don't want to include this in anything
rm -Rf .git

# And build
dpkg-buildpackage

# Nice output directory
cd ${BASEDIR}
mkdir -p output
mv dmdirc_${FINALVERSION}*.* output

# Clean Up
rm -Rf ${BUILDDIR}