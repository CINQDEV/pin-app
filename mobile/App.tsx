import { NavigationContainer } from "@react-navigation/native";
import { createBottomTabNavigator } from "@react-navigation/bottom-tabs";
import { StatusBar } from "expo-status-bar";
import { SafeAreaProvider } from "react-native-safe-area-context";
import { IslandsProvider, useIslands } from "./src/context/IslandsContext";
import { MapScreen } from "./src/screens/MapScreen";
import { ListScreen } from "./src/screens/ListScreen";
import { CatchBanner } from "./src/components/CatchBanner";

const Tab = createBottomTabNavigator();

function CatchBannerOverlay() {
  const { justCaught, dismissCaught } = useIslands();
  return <CatchBanner island={justCaught} onDismiss={dismissCaught} />;
}

export default function App() {
  return (
    <SafeAreaProvider>
      <IslandsProvider>
        <NavigationContainer>
          <CatchBannerOverlay />
          <Tab.Navigator screenOptions={{ headerShown: false }}>
            <Tab.Screen name="Map" component={MapScreen} />
            <Tab.Screen name="Islands" component={ListScreen} />
          </Tab.Navigator>
        </NavigationContainer>
        <StatusBar style="auto" />
      </IslandsProvider>
    </SafeAreaProvider>
  );
}
