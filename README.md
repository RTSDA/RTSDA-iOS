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

### Version 1.2.1
- Improved Bible verse formatting in splash screen
  - Removed verse numbers
  - Removed paragraph markers
  - Cleaned up parenthetical content
  - Better text formatting
- Enhanced bulletin view formatting
  - Improved header detection and styling
  - Better section organization
  - Consistent spacing and alignment
  - Cleaner text presentation

### Version 1.2
- Added Digital Bulletin system
  - View weekly church bulletins
  - Interactive hymn links
  - Bible verse links
  - PDF download option
- Updated minimum iOS version to 17.0
- Updated Xcode version requirement to 15.0

### Version 1.1
- Initial release
- Live streaming
- Sermon library
- Church information
- Beliefs reference

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

For any inquiries about the app, please contact the Rockville-Tolland SDA Church IT department. 