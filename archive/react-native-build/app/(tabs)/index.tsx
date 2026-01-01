import { View, Text, ScrollView, Pressable } from 'react-native';
import { Link } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';

export default function DashboardScreen() {
  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: '#1a1a1a' }} edges={['left', 'right']}>
      <ScrollView
        style={{ flex: 1 }}
        contentContainerStyle={{ padding: 16 }}
      >
        {/* Header */}
        <View style={{ marginBottom: 24 }}>
          <Text style={{ fontSize: 28, fontWeight: 'bold', color: '#fff' }}>
            BowlerTrax
          </Text>
          <Text style={{ fontSize: 16, color: '#718096', marginTop: 4 }}>
            Track your shots, improve your game
          </Text>
        </View>

        {/* Quick Actions */}
        <View style={{ marginBottom: 24 }}>
          <Text style={{ fontSize: 18, fontWeight: '600', color: '#fff', marginBottom: 12 }}>
            Quick Actions
          </Text>
          <View style={{ flexDirection: 'row', gap: 12 }}>
            <Link href="/record" asChild>
              <Pressable
                style={{
                  flex: 1,
                  backgroundColor: '#319795',
                  padding: 20,
                  borderRadius: 12,
                  alignItems: 'center',
                }}
              >
                <Text style={{ fontSize: 32, marginBottom: 8 }}>📹</Text>
                <Text style={{ color: '#fff', fontWeight: '600', fontSize: 16 }}>
                  New Session
                </Text>
              </Pressable>
            </Link>
            <Link href="/calibrate" asChild>
              <Pressable
                style={{
                  flex: 1,
                  backgroundColor: '#2d3748',
                  padding: 20,
                  borderRadius: 12,
                  alignItems: 'center',
                }}
              >
                <Text style={{ fontSize: 32, marginBottom: 8 }}>🎯</Text>
                <Text style={{ color: '#fff', fontWeight: '600', fontSize: 16 }}>
                  Calibrate
                </Text>
              </Pressable>
            </Link>
          </View>
        </View>

        {/* Recent Stats Placeholder */}
        <View style={{ marginBottom: 24 }}>
          <Text style={{ fontSize: 18, fontWeight: '600', color: '#fff', marginBottom: 12 }}>
            Your Stats
          </Text>
          <View
            style={{
              backgroundColor: '#2d3748',
              borderRadius: 12,
              padding: 16,
            }}
          >
            <View style={{ flexDirection: 'row', justifyContent: 'space-between', marginBottom: 16 }}>
              <StatCard label="Avg Speed" value="--" unit="mph" />
              <StatCard label="Avg Rev Rate" value="--" unit="rpm" />
            </View>
            <View style={{ flexDirection: 'row', justifyContent: 'space-between' }}>
              <StatCard label="Entry Angle" value="--" unit="°" />
              <StatCard label="Strike %" value="--" unit="%" />
            </View>
            <Text style={{ color: '#718096', textAlign: 'center', marginTop: 16 }}>
              Record shots to see your stats
            </Text>
          </View>
        </View>

        {/* Recent Sessions Placeholder */}
        <View>
          <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
            <Text style={{ fontSize: 18, fontWeight: '600', color: '#fff' }}>
              Recent Sessions
            </Text>
            <Link href="/sessions" asChild>
              <Pressable>
                <Text style={{ color: '#4fd1c5' }}>See All</Text>
              </Pressable>
            </Link>
          </View>
          <View
            style={{
              backgroundColor: '#2d3748',
              borderRadius: 12,
              padding: 24,
              alignItems: 'center',
            }}
          >
            <Text style={{ fontSize: 48, marginBottom: 8 }}>🎳</Text>
            <Text style={{ color: '#718096', textAlign: 'center' }}>
              No sessions yet{'\n'}Start recording to track your progress
            </Text>
          </View>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

function StatCard({ label, value, unit }: { label: string; value: string; unit: string }) {
  return (
    <View style={{ flex: 1, alignItems: 'center' }}>
      <Text style={{ color: '#718096', fontSize: 12, marginBottom: 4 }}>{label}</Text>
      <View style={{ flexDirection: 'row', alignItems: 'baseline' }}>
        <Text style={{ color: '#fff', fontSize: 24, fontWeight: 'bold' }}>{value}</Text>
        <Text style={{ color: '#718096', fontSize: 12, marginLeft: 2 }}>{unit}</Text>
      </View>
    </View>
  );
}
