# RTSDA Church Platform

Monorepo for the Rockville-Tolland Seventh-day Adventist Church platform, containing all web and mobile applications.

## Project Structure

- `web/` - Web application (JavaScript)
  - Main church website
  - Event management system
  - Firebase integration

- `android/` - Android application (Kotlin)
  - Native Android app
  - Event synchronization
  - Push notifications

- `ios/` - iOS application (Swift)
  - Native iOS app
  - Event synchronization
  - Push notifications
  - YouTube integration for sermons and livestreams
  - Calendar integration

- `shared/` - Shared resources
  - Documentation
  - Design assets
  - API specifications
  - Common utilities

## Development Setup

1. Clone this repository
2. Each platform has its own setup instructions in its respective directory
3. Firebase configuration is required for all platforms

### iOS Setup

1. Install Xcode 15 or later
2. Open `ios/RTSDA.xcodeproj`

3. Configure Firebase:
   ```bash
   # Copy the example Firebase config
   cp ios/RTSDA/GoogleService-Info.example.plist ios/RTSDA/GoogleService-Info.plist
   ```
   - Get your own `GoogleService-Info.plist` from Firebase Console:
     1. Go to [Firebase Console](https://console.firebase.google.com)
     2. Select your project
     3. Click the iOS app (com.rtsda.appr)
     4. Download the config file
     5. Replace the placeholder values in your local `GoogleService-Info.plist`
   - **IMPORTANT**: Never commit `GoogleService-Info.plist` to git!

4. Configure Remote Config:
   - In Firebase Console, go to Remote Config
   - Add parameter `youtube_api_key` with your YouTube API key
   - This key will be automatically used by all apps

5. Build and run the project

### Android Setup

1. Configure Firebase:
   ```bash
   # Copy the example Firebase config
   cp android/app/google-services.example.json android/app/google-services.json
   ```
   - Get your own `google-services.json` from Firebase Console
   - Replace the placeholder values
   - **IMPORTANT**: Never commit `google-services.json` to git!

### Environment Variables

The following configuration is managed through Firebase Remote Config:

- `youtube_api_key`: YouTube Data API v3 key
  - Must be configured with proper bundle IDs
  - Required for sermon and livestream features
  - Managed centrally through Firebase Console

### Sensitive Files

The following files contain sensitive information and are **not** committed to git:

1. `ios/RTSDA/GoogleService-Info.plist`
   - Contains Firebase API keys and configuration
   - Example template in `GoogleService-Info.example.plist`
   - Get your own copy from Firebase Console

2. `android/app/google-services.json`
   - Contains Firebase configuration for Android
   - Example template in `google-services.example.json`
   - Get your own copy from Firebase Console

3. Firebase Remote Config
   - Manages API keys and other sensitive configuration
   - Set up through Firebase Console
   - Changes are pushed to all apps automatically

### Best Practices for API Keys

1. **Never commit API keys or credentials to git**
2. Use Firebase Remote Config for managing keys across platforms
3. Keep example files up to date with placeholder values
4. Document all required keys in README
5. Use different keys for development and production
6. Regularly rotate keys for security

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Security

- Never commit API keys or sensitive credentials
- Use Firebase Remote Config for sensitive values
- Keep configuration files in `.gitignore`
- Follow platform security best practices

## License

This project uses a dual licensing approach:

### Application Source Code
The application source code is licensed under the GNU General Public License v3 (GPLv3). 
See the [LICENSE](LICENSE) file for details.

### Church Content
The content accessible through this application (including sermons, events, media, and other 
church-specific materials) is copyrighted by the Rockville-Tolland Seventh-day Adventist Church. 
All rights reserved. These materials are not covered by the GPL license and require proper 
authorization for use.

## Contact

For technical inquiries and contributions, please open an issue or pull request.

For permissions regarding church content usage, contact:
Rockville-Tolland Seventh-day Adventist Church
Administrative Office
[Church Address]
[Contact Information]
