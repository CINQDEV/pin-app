import { useRef, useState } from "react";
import { StyleSheet, View } from "react-native";
import MapView, { Circle, Marker, Region } from "react-native-maps";
import { useIslands } from "../context/IslandsContext";
import { CHECK_IN_RADIUS_METERS } from "../config";

const DEFAULT_REGION: Region = {
  latitude: 56.4907,
  longitude: -4.2026,
  latitudeDelta: 4,
  longitudeDelta: 4,
};

// With 1000+ islands worldwide, rendering every marker at once would tank map
// performance — only render pins inside (a little more than) the visible viewport.
const VIEWPORT_PADDING_FACTOR = 1.3;

function isInRegion(lat: number, lng: number, region: Region): boolean {
  const latPad = (region.latitudeDelta * VIEWPORT_PADDING_FACTOR) / 2;
  const lngPad = (region.longitudeDelta * VIEWPORT_PADDING_FACTOR) / 2;
  return (
    Math.abs(lat - region.latitude) <= latPad && Math.abs(lng - region.longitude) <= lngPad
  );
}

export function MapScreen() {
  const { islands, userCoords } = useIslands();
  const mapRef = useRef<MapView>(null);

  const initialRegion: Region = userCoords
    ? {
        latitude: userCoords.latitude,
        longitude: userCoords.longitude,
        latitudeDelta: 0.05,
        longitudeDelta: 0.05,
      }
    : DEFAULT_REGION;
  const [visibleRegion, setVisibleRegion] = useState<Region>(initialRegion);

  const visibleIslands = islands.filter((island) => isInRegion(island.lat, island.lng, visibleRegion));

  return (
    <View style={styles.container}>
      <MapView
        ref={mapRef}
        style={styles.map}
        initialRegion={initialRegion}
        onRegionChangeComplete={setVisibleRegion}
        showsUserLocation
        showsMyLocationButton
      >
        {userCoords && (
          <Circle
            center={userCoords}
            radius={CHECK_IN_RADIUS_METERS}
            strokeColor="rgba(46, 125, 50, 0.6)"
            fillColor="rgba(46, 125, 50, 0.15)"
          />
        )}
        {visibleIslands.map((island) => (
          <Marker
            key={island.id}
            coordinate={{ latitude: island.lat, longitude: island.lng }}
            title={island.name}
            description={island.description.slice(0, 120)}
            pinColor={island.checked ? "#2E7D32" : "#D32F2F"}
          />
        ))}
      </MapView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  map: {
    flex: 1,
  },
});
