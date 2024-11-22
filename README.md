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
3. Configure environment variables in Xcode:
   - Open scheme editor (Product > Scheme > Edit Scheme)
   - Add `YOUTUBE_API_KEY` in both Run and Release schemes
   - Get the API key from Google Cloud Console

4. Firebase Setup:
   - Get `GoogleService-Info.plist` from Firebase Console
   - Add it to `ios/RTSDA/`
   - Use `GoogleService-Info.example.plist` as a template

5. Build and run the project

### Environment Variables

The following environment variables are required:

- `YOUTUBE_API_KEY`: YouTube Data API v3 key
  - Must be configured with proper bundle ID (`com.rtsda.appr`)
  - Required for sermon and livestream features

### Sensitive Files

The following files contain sensitive information and are not committed to git:

1. `GoogleService-Info.plist` - Firebase configuration
   - Contains API keys and project configuration
   - Get from Firebase Console
   - Example template provided in `GoogleService-Info.example.plist`

2. Environment Variables
   - YouTube API key is managed through Xcode schemes
   - Required for both development and production

## Common Development Tasks

### Event System

The event system is implemented across all platforms with these common features:
- Firebase Firestore for data storage
- Server-side filtering using composite indexes
- Recurring event generation
- Real-time updates

### Best Practices

1. Keep implementations consistent across platforms
2. Use server-side filtering when possible
3. Follow platform-specific conventions
4. Document all shared functionality
5. Never commit sensitive information (API keys, credentials)
6. Use environment variables for sensitive configuration

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Security

- Never commit API keys or sensitive credentials
- Use environment variables for sensitive configuration
- Keep Firebase configuration files private
- Follow platform security best practices
