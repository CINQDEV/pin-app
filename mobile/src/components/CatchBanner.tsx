import { useEffect, useRef } from "react";
import { Animated, StyleSheet, Text } from "react-native";
import { Island } from "../api/islands";

interface CatchBannerProps {
  island: Island | null;
  onDismiss: () => void;
}

const VISIBLE_DURATION_MS = 2200;

export function CatchBanner({ island, onDismiss }: CatchBannerProps) {
  const translateY = useRef(new Animated.Value(-100)).current;

  useEffect(() => {
    if (!island) return;

    const sequence = Animated.sequence([
      Animated.spring(translateY, { toValue: 0, useNativeDriver: true }),
      Animated.delay(VISIBLE_DURATION_MS),
      Animated.timing(translateY, { toValue: -100, duration: 250, useNativeDriver: true }),
    ]);
    sequence.start(({ finished }) => {
      if (finished) onDismiss();
    });

    return () => sequence.stop();
  }, [island, onDismiss, translateY]);

  if (!island) return null;

  return (
    <Animated.View style={[styles.banner, { transform: [{ translateY }] }]}>
      <Text style={styles.title}>Island discovered!</Text>
      <Text style={styles.name}>{island.name}</Text>
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  banner: {
    position: "absolute",
    top: 0,
    left: 16,
    right: 16,
    backgroundColor: "#2E7D32",
    borderRadius: 12,
    paddingVertical: 12,
    paddingHorizontal: 16,
    zIndex: 10,
    elevation: 6,
    shadowColor: "#000",
    shadowOpacity: 0.2,
    shadowRadius: 6,
    shadowOffset: { width: 0, height: 3 },
  },
  title: {
    color: "#fff",
    fontWeight: "700",
    fontSize: 12,
    textTransform: "uppercase",
    letterSpacing: 0.5,
  },
  name: {
    color: "#fff",
    fontWeight: "600",
    fontSize: 18,
    marginTop: 2,
  },
});
