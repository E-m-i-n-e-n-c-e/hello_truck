# Google Maps Setup

## API Key Security

**IMPORTANT**: The Google Maps API key is stored in `android/app/src/main/res/values/strings.xml` and is configured to be ignored by Git.

### Current API Key
- **API Key**: `AIzaSyBqTOs9JWbrHqOIO10oGKpLhuvou37S6Aw`
- **Platform**: Android only (iOS not configured yet)

### Security Notes
1. The `strings.xml` file is added to `.gitignore` to prevent API key exposure
2. Never commit API keys to version control
3. For production, consider using environment variables or secure key management

## Features Implemented

### Map Screen (`lib/screens/map_screen.dart`)
- **Current Location**: Automatically gets and displays user's current location with a blue pin
- **Location Permissions**: Handles all location permission scenarios
- **Delivery Selection**: Tap anywhere on the map to set delivery location (red pin)
- **Address Input**: Tap on delivery pin to enter a custom address
- **Confirmation Flow**: Review pickup and delivery locations before confirming

### Permissions Added
- `ACCESS_FINE_LOCATION`: For precise location
- `ACCESS_COARSE_LOCATION`: For approximate location

## Usage Flow
1. App requests location permission
2. Shows user's current location on map with blue pin
3. User taps anywhere on map to set delivery location (red pin)
4. User can tap delivery pin to enter detailed address
5. Confirmation dialog shows both locations
6. User confirms to proceed with booking (currently shows placeholder message)

## Next Steps
- Integrate with booking API
- Add reverse geocoding to automatically get addresses
- Add route calculation between pickup and delivery
- Implement iOS configuration when needed