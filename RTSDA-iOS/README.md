# RTSDA iOS App

## Setup Instructions

### Firebase Configuration
1. Copy `GoogleService-Info.plist.template` to `GoogleService-Info.plist`
2. Replace the placeholder values with your Firebase configuration:
   - `YOUR_API_KEY`: Firebase API Key
   - `YOUR_GCM_SENDER_ID`: Firebase GCM Sender ID
   - `YOUR_PROJECT_ID`: Firebase Project ID
   - `YOUR_STORAGE_BUCKET`: Firebase Storage Bucket
   - `YOUR_GOOGLE_APP_ID`: Firebase App ID

You can find these values in your Firebase Console under Project Settings.

**Note:** Never commit `GoogleService-Info.plist` to version control as it contains sensitive API keys.

## Development
1. Open `RTSDA.xcodeproj` in Xcode
2. Build and run the project

## Security Notes
- Keep your API keys and sensitive configuration data secure
- Use the template file for reference and local development setup
- Ensure `GoogleService-Info.plist` is in `.gitignore`
