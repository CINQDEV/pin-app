import * as Location from "expo-location";
import { useEffect, useRef, useState } from "react";

export type LocationAccuracyWarning = "reduced-precision" | "coarse-only" | null;

interface UseLocationResult {
  coords: { latitude: number; longitude: number } | null;
  errorMessage: string | null;
  accuracyWarning: LocationAccuracyWarning;
}

export function useLocation(): UseLocationResult {
  const [coords, setCoords] = useState<UseLocationResult["coords"]>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [accuracyWarning, setAccuracyWarning] = useState<LocationAccuracyWarning>(null);
  const subscriptionRef = useRef<Location.LocationSubscription | null>(null);

  useEffect(() => {
    let cancelled = false;

    async function start() {
      const { status, ios, android } = await Location.requestForegroundPermissionsAsync();
      if (status !== Location.PermissionStatus.GRANTED) {
        if (!cancelled) setErrorMessage("Location permission was not granted.");
        return;
      }
      if (!cancelled) {
        if (ios?.accuracy === "reduced") {
          setAccuracyWarning("reduced-precision");
        } else if (android?.accuracy === "coarse") {
          setAccuracyWarning("coarse-only");
        }
      }

      const subscription = await Location.watchPositionAsync(
        {
          accuracy: Location.Accuracy.BestForNavigation,
          distanceInterval: 5,
          timeInterval: 2000,
        },
        (location) => {
          if (cancelled) return;
          setCoords({
            latitude: location.coords.latitude,
            longitude: location.coords.longitude,
          });
        }
      );
      subscriptionRef.current = subscription;
    }

    start().catch((error: unknown) => {
      if (!cancelled) {
        setErrorMessage(error instanceof Error ? error.message : "Failed to start location tracking.");
      }
    });

    return () => {
      cancelled = true;
      subscriptionRef.current?.remove();
    };
  }, []);

  return { coords, errorMessage, accuracyWarning };
}
