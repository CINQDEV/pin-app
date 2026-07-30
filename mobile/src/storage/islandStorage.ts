import AsyncStorage from "@react-native-async-storage/async-storage";
import { Island } from "../api/islands";

const CHECKED_IDS_KEY = "pinapp:checkedIslandIds";
const ISLANDS_CACHE_KEY = "pinapp:islandsCache";

export async function loadCheckedIds(): Promise<Set<string>> {
  const raw = await AsyncStorage.getItem(CHECKED_IDS_KEY);
  if (!raw) return new Set();
  try {
    return new Set<string>(JSON.parse(raw));
  } catch {
    return new Set();
  }
}

export async function saveCheckedIds(ids: Set<string>): Promise<void> {
  await AsyncStorage.setItem(CHECKED_IDS_KEY, JSON.stringify(Array.from(ids)));
}

export async function loadCachedIslands(): Promise<Island[] | null> {
  const raw = await AsyncStorage.getItem(ISLANDS_CACHE_KEY);
  if (!raw) return null;
  try {
    return JSON.parse(raw) as Island[];
  } catch {
    return null;
  }
}

export async function saveCachedIslands(islands: Island[]): Promise<void> {
  await AsyncStorage.setItem(ISLANDS_CACHE_KEY, JSON.stringify(islands));
}
