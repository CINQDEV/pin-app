# Pin App

Mobile app for "island bagging": fetches the full island list from [searchisle.com](https://searchisle.com)'s public REST API and auto-checks each one off (like a Pokémon Go catch) when you get within 50 meters, tracked live on a map and a list.

## Structure
- `mobile/` — Expo (React Native + TypeScript) app. No backend — it talks straight to searchisle.com and stores your checked-off islands on-device.

## Data source
`GET https://searchisle.com/wp-json/wp/v2/islands` — a public, read-only WordPress REST API, ~1,100 islands, each with a lat/lng under `acf.island_map`. See `mobile/src/api/islands.ts` for the fetch/pagination/parsing logic.

Because this API is read-only and not ours, "checked" state can't be written back to it — it's stored locally on the device via `@react-native-async-storage/async-storage` (`mobile/src/storage/islandStorage.ts`), alongside a cached copy of the island list so the app has something to show immediately on a cold start while it refetches in the background.

## Running it

```
cd mobile
npm install
npx expo start
```
Scan the QR code with Expo Go on a physical device (simulators don't have real GPS — use Xcode's custom-location or Android emulator's extended-controls location to simulate being near an island instead).

## Notes
- Foreground-only location tracking — checks only happen while the app is open, no background geofencing.
- The map only renders markers inside (a bit more than) the current viewport, since rendering 1,100+ markers at once would be slow — the proximity check itself still runs against every island, not just visible ones.
- Checked state and the island list cache are per-device (AsyncStorage) — reinstalling the app or clearing storage resets progress.
