# Pin App

Native iOS app (Swift/SwiftUI) for "island bagging": fetches the full island list from [searchisle.com](https://searchisle.com)'s public REST API and auto-checks each one off (like a Pokémon Go catch) when you get within 50 meters, tracked live on a map and a list.

## Structure
- `ios/` — Swift/SwiftUI app, zero third-party dependencies (MapKit + CoreLocation cover everything Expo's `react-native-maps`/`expo-location` used to). No backend — it talks straight to searchisle.com and stores your checked-off islands on-device.

## Data source
`GET https://searchisle.com/wp-json/wp/v2/islands` — a public, read-only WordPress REST API, ~1,100 islands, each with a lat/lng under `acf.island_map`. See `ios/PinApp/Networking/SearchIsleAPI.swift` for the fetch/pagination/parsing logic.

Because this API is read-only and not ours, "checked" state can't be written back to it — it's stored locally on the device via `UserDefaults` (`ios/PinApp/Persistence/CheckedIslandsStore.swift`), alongside a cached copy of the island list so the app has something to show immediately on a cold start while it refetches in the background.

## Running it

### In Xcode (recommended)
Open `ios/PinApp.xcodeproj` in Xcode, pick a simulator or your device as the run destination, and hit ▶️ Run.

### From the command line
```
cd ios
xcodegen generate               # only needed after editing project.yml, or if PinApp.xcodeproj is missing
xcodebuild -project PinApp.xcodeproj -scheme PinApp \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```
`project.yml` is the source of truth for the Xcode project — `PinApp.xcodeproj` is generated from it via [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`) and isn't meant to be hand-edited.

### On a physical iPhone
Open the project in Xcode, select your iPhone as the run destination, and under the target's **Signing & Capabilities** tab sign in with your Apple ID (a free personal team is fine) so Xcode can provision the device. The first run will ask you to trust the developer certificate on the phone (Settings ▸ General ▸ VPN & Device Management).

## Testing the 50 m catch without traveling
Real GPS is real islands — mostly in the UK — so to trigger a catch without visiting one:
- **Simulator**: Xcode ▸ Debug ▸ Simulate Location (pick a location or add a custom one), or from the command line: `xcrun simctl location booted set <lat>,<lng>` using coordinates from the Islands tab.
- **Physical device**: no built-in fake-location support from Apple — you'd need to actually be within 50 m of a charted island, or use Xcode's GPX-based route simulation while debugging (Debug ▸ Simulate Location ▸ works the same for a device attached and running from Xcode).

## Notes
- Foreground-only location tracking — checks only happen while the app is open, no background geofencing.
- The map only renders markers inside (a bit more than) the current viewport, since rendering 1,100+ markers at once would be slow — the proximity check itself still runs against every island, not just visible ones.
- Checked state and the island list cache are per-device (`UserDefaults`) — deleting the app or resetting the simulator's content resets progress.
