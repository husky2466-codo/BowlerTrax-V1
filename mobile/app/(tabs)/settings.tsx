import { View, Text, Pressable, Switch, ScrollView } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useState } from 'react';
import { Link } from 'expo-router';

export default function SettingsScreen() {
  const [isRightHanded, setIsRightHanded] = useState(true);
  const [autoSaveVideos, setAutoSaveVideos] = useState(true);
  const [showPreviousShot, setShowPreviousShot] = useState(true);
  const [hapticFeedback, setHapticFeedback] = useState(true);

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: '#1a1a1a' }} edges={['left', 'right']}>
      <ScrollView contentContainerStyle={{ padding: 16 }}>
        {/* Bowling Preferences */}
        <Text style={{ fontSize: 18, fontWeight: '600', color: '#fff', marginBottom: 12 }}>
          Bowling Preferences
        </Text>
        <View
          style={{
            backgroundColor: '#2d3748',
            borderRadius: 12,
            marginBottom: 24,
          }}
        >
          <SettingRow label="Dominant Hand">
            <Pressable
              onPress={() => setIsRightHanded(!isRightHanded)}
              style={{
                backgroundColor: isRightHanded ? '#319795' : '#4a5568',
                paddingHorizontal: 16,
                paddingVertical: 8,
                borderRadius: 8,
              }}
            >
              <Text style={{ color: '#fff', fontWeight: '600' }}>
                {isRightHanded ? 'Right' : 'Left'}
              </Text>
            </Pressable>
          </SettingRow>

          <SettingDivider />

          <Link href="/calibrate" asChild>
            <Pressable style={{ padding: 16, flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' }}>
              <View>
                <Text style={{ color: '#fff', fontSize: 16 }}>Lane Calibration</Text>
                <Text style={{ color: '#718096', fontSize: 12, marginTop: 2 }}>
                  No calibration saved
                </Text>
              </View>
              <Text style={{ color: '#4fd1c5' }}>Configure →</Text>
            </Pressable>
          </Link>
        </View>

        {/* Recording Settings */}
        <Text style={{ fontSize: 18, fontWeight: '600', color: '#fff', marginBottom: 12 }}>
          Recording Settings
        </Text>
        <View
          style={{
            backgroundColor: '#2d3748',
            borderRadius: 12,
            marginBottom: 24,
          }}
        >
          <SettingRow label="Auto-save Videos">
            <Switch
              value={autoSaveVideos}
              onValueChange={setAutoSaveVideos}
              trackColor={{ false: '#4a5568', true: '#319795' }}
              thumbColor="#fff"
            />
          </SettingRow>

          <SettingDivider />

          <SettingRow label="Show Previous Shot Comparison">
            <Switch
              value={showPreviousShot}
              onValueChange={setShowPreviousShot}
              trackColor={{ false: '#4a5568', true: '#319795' }}
              thumbColor="#fff"
            />
          </SettingRow>

          <SettingDivider />

          <SettingRow label="Haptic Feedback">
            <Switch
              value={hapticFeedback}
              onValueChange={setHapticFeedback}
              trackColor={{ false: '#4a5568', true: '#319795' }}
              thumbColor="#fff"
            />
          </SettingRow>
        </View>

        {/* Ball Profiles */}
        <Text style={{ fontSize: 18, fontWeight: '600', color: '#fff', marginBottom: 12 }}>
          Ball Profiles
        </Text>
        <View
          style={{
            backgroundColor: '#2d3748',
            borderRadius: 12,
            padding: 16,
            marginBottom: 24,
          }}
        >
          <Text style={{ color: '#718096', textAlign: 'center', marginBottom: 12 }}>
            Save ball colors for easier tracking
          </Text>
          <Pressable
            style={{
              borderWidth: 2,
              borderColor: '#4a5568',
              borderStyle: 'dashed',
              borderRadius: 8,
              padding: 16,
              alignItems: 'center',
            }}
          >
            <Text style={{ color: '#4fd1c5', fontWeight: '600' }}>+ Add Ball Profile</Text>
          </Pressable>
        </View>

        {/* Data Management */}
        <Text style={{ fontSize: 18, fontWeight: '600', color: '#fff', marginBottom: 12 }}>
          Data Management
        </Text>
        <View
          style={{
            backgroundColor: '#2d3748',
            borderRadius: 12,
            marginBottom: 24,
          }}
        >
          <Pressable style={{ padding: 16 }}>
            <Text style={{ color: '#fff', fontSize: 16 }}>Export Data</Text>
            <Text style={{ color: '#718096', fontSize: 12, marginTop: 2 }}>
              Export sessions as JSON or CSV
            </Text>
          </Pressable>

          <SettingDivider />

          <Pressable style={{ padding: 16 }}>
            <Text style={{ color: '#e53e3e', fontSize: 16 }}>Clear All Data</Text>
            <Text style={{ color: '#718096', fontSize: 12, marginTop: 2 }}>
              Delete all sessions and calibrations
            </Text>
          </Pressable>
        </View>

        {/* About */}
        <Text style={{ fontSize: 18, fontWeight: '600', color: '#fff', marginBottom: 12 }}>
          About
        </Text>
        <View
          style={{
            backgroundColor: '#2d3748',
            borderRadius: 12,
            padding: 16,
          }}
        >
          <View style={{ alignItems: 'center' }}>
            <Text style={{ fontSize: 32, marginBottom: 8 }}>🎳</Text>
            <Text style={{ color: '#fff', fontSize: 18, fontWeight: 'bold' }}>BowlerTrax</Text>
            <Text style={{ color: '#718096', marginTop: 4 }}>Version 1.0.0</Text>
            <Text style={{ color: '#718096', marginTop: 8, textAlign: 'center' }}>
              Personal bowling analytics app inspired by LaneTrax and Kegel Specto.
            </Text>
          </View>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

function SettingRow({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <View
      style={{
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        padding: 16,
      }}
    >
      <Text style={{ color: '#fff', fontSize: 16 }}>{label}</Text>
      {children}
    </View>
  );
}

function SettingDivider() {
  return <View style={{ height: 1, backgroundColor: '#4a5568', marginHorizontal: 16 }} />;
}
