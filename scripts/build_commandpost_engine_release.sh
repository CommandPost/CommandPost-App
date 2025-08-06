#!/bin/bash

#
# COMMANDPOST ENGINE BUILD RELEASE SCRIPT:
#

set -eu
set -o pipefail

#
# Define Variables:
#

export SCRIPT_HOME ; SCRIPT_HOME="$(dirname "$(greadlink -f "$0")")"
export COMMANDPOST_ENGINE_HOME ; COMMANDPOST_ENGINE_HOME="$(greadlink -f "${SCRIPT_HOME}/../")"

#
# Generate Appcast:
#

function generate_appcast() {

  echo "  * Generating New AppCast..."

  #
  # Generate DSA Signature (legacy for Sparkle 1.0):
  #

  export SPARKLE_DSA_SIGNATURE
  SPARKLE_DSA_SIGNATURE="$(${COMMANDPOST_ENGINE_HOME}/../CommandPost/scripts/inc/sparkle1/sign_update "${COMMANDPOST_ENGINE_HOME}/build/CommandPostEngine.zip" "${COMMANDPOST_ENGINE_HOME}/../dsa_priv.pem")"

  #
  # Generate EdDSA Signature (for Sparkle 2.0):
  #

  export SPARKLE_ED_SIGNATURE
  SPARKLE_ED_SIGNATURE="$(${COMMANDPOST_ENGINE_HOME}/../CommandPost/scripts/inc/sparkle2/sign_update "${COMMANDPOST_ENGINE_HOME}/build/CommandPostEngine.zip")"

  #
  # Get Build Number from plist:
  #

  local BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "${COMMANDPOST_ENGINE_HOME}/build/CommandPost Engine.app/Contents/Info.plist")
  local VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${COMMANDPOST_ENGINE_HOME}/build/CommandPost Engine.app/Contents/Info.plist")

  touch "${COMMANDPOST_ENGINE_HOME}/build/appcast.xml"
  echo "
		<item>
			<title>Version ${VERSION}</title>
			<sparkle:releaseNotesLink>https://commandpost.github.io/CommandPost/releasenotes.html</sparkle:releaseNotesLink>
			<pubDate>$(date +"%a, %e %b %Y %H:%M:%S %z")</pubDate>
			<enclosure url=\"https://github.com/CommandPost/CommandPostEngineReleases/releases/latest/download/CommandPostEngine.zip\"
				sparkle:version=\"${BUILD_NUMBER}\"
                sparkle:shortVersionString=\"${VERSION}\"
				sparkle:dsaSignature=\"${SPARKLE_DSA_SIGNATURE}\"
				${SPARKLE_ED_SIGNATURE}
				type=\"application/octet-stream\"
			/>
			<sparkle:minimumSystemVersion>10.15</sparkle:minimumSystemVersion>
		</item>" >> "${COMMANDPOST_ENGINE_HOME}/build/appcast.xml"
}

#
# Build CommandPost Engine:
#

echo " * Quitting any active CommandPost instances..."
killall CommandPost || true

echo " * Moving to CommandPost Engine Directory..."
cd "${COMMANDPOST_ENGINE_HOME}/"

echo " * Cleaning up prior to build..."
./scripts/build.sh clean

echo " * Building CommandPost Engine Docs..."
./scripts/build.sh docs

echo " * Building CommandPost Engine..."
./scripts/build.sh build -s Release -c Release -d

echo " * Validating CommandPost Engine..."
./scripts/build.sh validate

echo " * Notorizing CommandPost Engine..."
./scripts/build.sh notarize

echo " * Generating new AppCast..."
generate_appcast

echo " * CommandPost Engine has been successfully built!"