import { Tabs } from 'expo-router';
import { Platform } from 'react-native';

// Simple icon components (will be replaced with proper icons later)
const TabIcon = ({ name, focused }: { name: string; focused: boolean }) => {
  const icons: Record<string, string> = {
    index: focused ? '🎯' : '◯',
    record: focused ? '📹' : '○',
    sessions: focused ? '📊' : '▢',
    settings: focused ? '⚙️' : '⛭',
  };
  return null; // Icons handled by tabBarIcon
};

export default function TabLayout() {
  return (
    <Tabs
      screenOptions={{
        tabBarActiveTintColor: '#4fd1c5',
        tabBarInactiveTintColor: '#718096',
        tabBarStyle: {
          backgroundColor: '#1a202c',
          borderTopColor: '#2d3748',
          borderTopWidth: 1,
          paddingTop: 8,
          paddingBottom: Platform.OS === 'ios' ? 24 : 8,
          height: Platform.OS === 'ios' ? 88 : 64,
        },
        tabBarLabelStyle: {
          fontSize: 12,
          fontWeight: '600',
        },
        headerStyle: {
          backgroundColor: '#1a1a1a',
        },
        headerTintColor: '#fff',
        headerTitleStyle: {
          fontWeight: 'bold',
        },
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: 'Dashboard',
          tabBarLabel: 'Home',
          tabBarIcon: ({ focused, color }) => (
            // Placeholder - will add proper icons
            null
          ),
        }}
      />
      <Tabs.Screen
        name="record"
        options={{
          title: 'Record Shot',
          tabBarLabel: 'Record',
          tabBarIcon: ({ focused, color }) => null,
        }}
      />
      <Tabs.Screen
        name="sessions"
        options={{
          title: 'Sessions',
          tabBarLabel: 'Sessions',
          tabBarIcon: ({ focused, color }) => null,
        }}
      />
      <Tabs.Screen
        name="settings"
        options={{
          title: 'Settings',
          tabBarLabel: 'Settings',
          tabBarIcon: ({ focused, color }) => null,
        }}
      />
    </Tabs>
  );
}
