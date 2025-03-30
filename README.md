# RTSDA iOS App

The official iOS app for the Rockville-Tolland Seventh-day Adventist Church. This app provides easy access to church services, media content, and information.

## Features

- **Live Streaming**: Watch church services live through OwnCast integration
- **Sermon Library**: Access archived sermons and special programs via Jellyfin
- **Digital Bulletin**: 
  - View weekly church bulletins
  - Interactive hymn links that open in the Adventist Hymnal app
  - Bible verse links that open in YouVersion Bible app
  - PDF download option for offline viewing
- **Church Bulletin**: Stay updated with church announcements and events
- **Church Information**: Access church beliefs, contact information, and more

## Technical Details

- Built with SwiftUI
- Minimum iOS version: 17.0
- Uses async/await for network operations
- Integrates with multiple services:
  - Jellyfin for video content
  - OwnCast for live streaming
  - PocketBase for church data
  - YouVersion Bible API for verse content
  - Adventist Hymnal app integration

## Building the App

1. Clone the repository
2. Open `RTSDA.xcodeproj` in Xcode
3. Build and run the project

## Requirements

- Xcode 15.0 or later
- iOS 17.0 or later
- Swift 5.9 or later

## Version History

- **1.2**: Added digital bulletin system with interactive hymn and Bible verse links
- **1.1**: Initial release with basic church information and live streaming

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

For any inquiries about the app, please contact the Rockville-Tolland SDA Church IT department. 