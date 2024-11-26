#!/bin/bash

# Find the most recently modified .xcarchive file
ARCHIVE_PATH=$(find ~/Library/Developer/Xcode/Archives -name "*.xcarchive" -type d -print0 | xargs -0 ls -td | head -n 1)

if [ -z "$ARCHIVE_PATH" ]; then
    echo "No .xcarchive file found"
    exit 1
fi

echo "Found archive at: $ARCHIVE_PATH"

# Path to the dSYM folder
DSYM_PATH="$ARCHIVE_PATH/dSYMs"

if [ ! -d "$DSYM_PATH" ]; then
    echo "dSYMs folder not found at: $DSYM_PATH"
    exit 1
fi

echo "Found dSYMs at: $DSYM_PATH"

# Path to Firebase Crashlytics upload script (for SPM)
DERIVED_DATA_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "RTSDA-*" -type d | head -n 1)
UPLOAD_SYMBOLS_PATH="$DERIVED_DATA_PATH/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/upload-symbols"

if [ ! -f "$UPLOAD_SYMBOLS_PATH" ]; then
    echo "Firebase upload-symbols script not found at: $UPLOAD_SYMBOLS_PATH"
    echo "Please ensure Firebase Crashlytics is properly installed via Swift Package Manager"
    exit 1
fi

echo "Found upload-symbols script at: $UPLOAD_SYMBOLS_PATH"

# Upload dSYMs to Firebase
"$UPLOAD_SYMBOLS_PATH" -gsp "./RTSDA/GoogleService-Info.plist" -p ios "$DSYM_PATH"
