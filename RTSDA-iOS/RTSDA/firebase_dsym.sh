#!/bin/bash

# Get the path to the archive's dSYMs
DSYM_PATH="${ARCHIVE_PATH}/dSYMs"

# Create directory if it doesn't exist
mkdir -p "${DSYM_PATH}"

# Copy Firebase related dSYMs
find "${BUILD_DIR}" -name "*.dSYM" | while read DSYM; do
    if [[ $DSYM == *"Firebase"* ]] || [[ $DSYM == *"grpc"* ]] || [[ $DSYM == *"absl"* ]] || [[ $DSYM == *"openssl"* ]]; then
        cp -R "$DSYM" "${DSYM_PATH}/"
    fi
done

# Generate dSYMs for SPM packages
find "${BUILD_DIR}/SourcePackages" -name "*.framework" | while read FRAMEWORK; do
    FRAMEWORK_DSYM="${FRAMEWORK}.dSYM"
    if [ ! -d "$FRAMEWORK_DSYM" ]; then
        xcrun dsymutil "$FRAMEWORK" -o "$FRAMEWORK_DSYM"
        if [ -d "$FRAMEWORK_DSYM" ]; then
            cp -R "$FRAMEWORK_DSYM" "${DSYM_PATH}/"
        fi
    fi
done
