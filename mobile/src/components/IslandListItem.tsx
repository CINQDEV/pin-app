import { StyleSheet, Text, View } from "react-native";
import { IslandWithStatus } from "../context/IslandsContext";

function formatDistance(meters: number | null): string {
  if (meters === null) return "…";
  if (meters < 1000) return `${Math.round(meters)} m away`;
  return `${(meters / 1000).toFixed(1)} km away`;
}

export function IslandListItem({ island }: { island: IslandWithStatus }) {
  return (
    <View style={[styles.row, island.checked && styles.rowChecked]}>
      <View style={styles.badge}>
        <Text style={styles.badgeText}>{island.checked ? "✓" : ""}</Text>
      </View>
      <View style={styles.info}>
        <Text style={[styles.name, island.checked && styles.nameChecked]}>{island.name}</Text>
        {island.description.length > 0 && (
          <Text style={styles.description} numberOfLines={2}>
            {island.description}
          </Text>
        )}
      </View>
      <Text style={styles.distance}>{formatDistance(island.distanceMeters)}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: "row",
    alignItems: "center",
    paddingVertical: 14,
    paddingHorizontal: 16,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: "#ddd",
  },
  rowChecked: {
    backgroundColor: "#F1F8F1",
  },
  badge: {
    width: 28,
    height: 28,
    borderRadius: 14,
    borderWidth: 2,
    borderColor: "#2E7D32",
    alignItems: "center",
    justifyContent: "center",
    marginRight: 12,
  },
  badgeText: {
    color: "#2E7D32",
    fontWeight: "700",
  },
  info: {
    flex: 1,
  },
  name: {
    fontSize: 16,
    fontWeight: "600",
    color: "#111",
  },
  nameChecked: {
    color: "#2E7D32",
  },
  description: {
    fontSize: 13,
    color: "#666",
    marginTop: 2,
  },
  distance: {
    fontSize: 13,
    color: "#333",
    marginLeft: 8,
  },
});
