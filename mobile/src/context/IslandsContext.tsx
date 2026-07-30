import {
  createContext,
  PropsWithChildren,
  useCallback,
  useContext,
  useEffect,
  useRef,
  useState,
} from "react";
import { fetchAllIslands, Island } from "../api/islands";
import { LocationAccuracyWarning, useLocation } from "../hooks/useLocation";
import { CHECK_IN_RADIUS_METERS } from "../config";
import { haversineDistance } from "../utils/distance";
import { loadCachedIslands, loadCheckedIds, saveCachedIslands, saveCheckedIds } from "../storage/islandStorage";

export interface IslandWithStatus extends Island {
  checked: boolean;
  distanceMeters: number | null;
}

interface IslandsContextValue {
  islands: IslandWithStatus[];
  loading: boolean;
  loadError: string | null;
  userCoords: { latitude: number; longitude: number } | null;
  locationError: string | null;
  accuracyWarning: LocationAccuracyWarning;
  justCaught: Island | null;
  refresh: () => void;
  dismissCaught: () => void;
}

const IslandsContext = createContext<IslandsContextValue | null>(null);

export function IslandsProvider({ children }: PropsWithChildren) {
  const [islands, setIslands] = useState<Island[]>([]);
  const [checkedIds, setCheckedIds] = useState<Set<string>>(new Set());
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [justCaught, setJustCaught] = useState<Island | null>(null);
  const { coords, errorMessage, accuracyWarning } = useLocation();
  const checkingInFlight = useRef(new Set<string>());

  const refresh = useCallback(() => {
    setLoading(true);
    setLoadError(null);
    fetchAllIslands()
      .then((fetched) => {
        setIslands(fetched);
        saveCachedIslands(fetched).catch(() => {});
      })
      .catch((error: unknown) => {
        setLoadError(error instanceof Error ? error.message : "Failed to load islands.");
      })
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => {
    loadCheckedIds().then(setCheckedIds);
    loadCachedIslands().then((cached) => {
      if (cached && cached.length > 0) {
        setIslands(cached);
        setLoading(false);
      }
      // Always hit the network too, so a cold cache is filled and a warm one stays fresh.
      refresh();
    });
  }, [refresh]);

  // Proximity check-in: on every fix, see if we're within range of an unchecked
  // island and, if so, mark it caught locally (persisted to AsyncStorage).
  useEffect(() => {
    if (!coords) return;

    for (const island of islands) {
      if (checkedIds.has(island.id) || checkingInFlight.current.has(island.id)) continue;
      const distance = haversineDistance(coords.latitude, coords.longitude, island.lat, island.lng);
      if (distance <= CHECK_IN_RADIUS_METERS) {
        checkingInFlight.current.add(island.id);
        setCheckedIds((prev) => {
          const next = new Set(prev);
          next.add(island.id);
          saveCheckedIds(next).catch(() => {});
          return next;
        });
        setJustCaught(island);
        checkingInFlight.current.delete(island.id);
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [coords, islands]);

  const islandsWithStatus: IslandWithStatus[] = islands
    .map((island) => ({
      ...island,
      checked: checkedIds.has(island.id),
      distanceMeters: coords
        ? haversineDistance(coords.latitude, coords.longitude, island.lat, island.lng)
        : null,
    }))
    .sort((a, b) => (a.distanceMeters ?? Infinity) - (b.distanceMeters ?? Infinity));

  return (
    <IslandsContext.Provider
      value={{
        islands: islandsWithStatus,
        loading,
        loadError,
        userCoords: coords,
        locationError: errorMessage,
        accuracyWarning,
        justCaught,
        refresh,
        dismissCaught: () => setJustCaught(null),
      }}
    >
      {children}
    </IslandsContext.Provider>
  );
}

export function useIslands(): IslandsContextValue {
  const ctx = useContext(IslandsContext);
  if (!ctx) throw new Error("useIslands must be used within an IslandsProvider");
  return ctx;
}
