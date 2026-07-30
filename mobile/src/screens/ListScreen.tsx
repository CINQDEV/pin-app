import { FlatList, RefreshControl, StyleSheet, Text, View } from "react-native";
import { useIslands } from "../context/IslandsContext";
import { IslandListItem } from "../components/IslandListItem";

export function ListScreen() {
  const { islands, loading, loadError, locationError, accuracyWarning, refresh } = useIslands();

  return (
    <View style={styles.container}>
      {(locationError || accuracyWarning) && (
        <View style={styles.warningBanner}>
          <Text style={styles.warningText}>
            {locationError ??
              (accuracyWarning === "reduced-precision"
                ? "Precise location is off — 50 m check-ins may be unreliable."
                : "Only coarse location is available — 50 m check-ins may be unreliable.")}
          </Text>
        </View>
      )}
      {loadError && (
        <View style={styles.warningBanner}>
          <Text style={styles.warningText}>{loadError}</Text>
        </View>
      )}
      <FlatList
        data={islands}
        keyExtractor={(island) => island.id}
        renderItem={({ item }) => <IslandListItem island={item} />}
        refreshControl={<RefreshControl refreshing={loading} onRefresh={refresh} />}
        contentContainerStyle={islands.length === 0 ? styles.empty : undefined}
        ListEmptyComponent={
          !loading ? <Text style={styles.emptyText}>No islands loaded yet.</Text> : null
        }
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#fff",
  },
  warningBanner: {
    backgroundColor: "#FFF3CD",
    paddingVertical: 8,
    paddingHorizontal: 16,
  },
  warningText: {
    color: "#856404",
    fontSize: 13,
  },
  empty: {
    flexGrow: 1,
    alignItems: "center",
    justifyContent: "center",
  },
  emptyText: {
    color: "#888",
  },
});
