import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { useEffect } from 'react';
import { View } from 'react-native';
import '../global.css';

export default function RootLayout() {
  return (
    <View style={{ flex: 1, backgroundColor: '#1a1a1a' }}>
      <StatusBar style="light" />
      <Stack
        screenOptions={{
          headerStyle: {
            backgroundColor: '#1a1a1a',
          },
          headerTintColor: '#fff',
          headerTitleStyle: {
            fontWeight: 'bold',
          },
          contentStyle: {
            backgroundColor: '#1a1a1a',
          },
        }}
      >
        <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
        <Stack.Screen
          name="calibrate"
          options={{
            title: 'Calibrate Lane',
            presentation: 'modal',
          }}
        />
        <Stack.Screen
          name="session/[id]"
          options={{
            title: 'Session Details',
          }}
        />
        <Stack.Screen
          name="shot/[id]"
          options={{
            title: 'Shot Analysis',
          }}
        />
      </Stack>
    </View>
  );
}
