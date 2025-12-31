import { View, Text, FlatList, Pressable } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useLocalSearchParams, Link } from 'expo-router';

// Placeholder shot type
interface ShotItem {
  id: string;
  shotNumber: number;
  speedMph: number;
  revRateRpm: number;
  entryAngleDeg: number;
  result: string;
}

export default function SessionDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();

  // Placeholder data - would come from database
  const session = {
    id,
    date: 'Dec 30, 2024',
    centerName: 'Practice Session',
    laneNumber: 5,
    oilPattern: 'House',
    shotCount: 0,
    shots: [] as ShotItem[],
    stats: {
      avgSpeedMph: 0,
      avgRevRateRpm: 0,
      avgEntryAngle: 0,
      strikeRate: 0,
    },
  };

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: '#1a1a1a' }} edges={['left', 'right']}>
      {/* Session header */}
      <View style={{ padding: 16, backgroundColor: '#2d3748', marginBottom: 16 }}>
        <View style={{ flexDirection: 'row', justifyContent: 'space-between', marginBottom: 8 }}>
          <Text style={{ color: '#fff', fontSize: 20, fontWeight: 'bold' }}>
            {session.centerName}
          </Text>
          <Text style={{ color: '#718096' }}>{session.date}</Text>
        </View>
        <View style={{ flexDirection: 'row', gap: 16 }}>
          <Text style={{ color: '#718096' }}>Lane {session.laneNumber || '--'}</Text>
          <Text style={{ color: '#718096' }}>{session.oilPattern} Pattern</Text>
          <Text style={{ color: '#718096' }}>{session.shotCount} shots</Text>
        </View>
      </View>

      {/* Stats summary */}
      <View style={{ paddingHorizontal: 16, marginBottom: 16 }}>
        <Text style={{ color: '#fff', fontSize: 16, fontWeight: '600', marginBottom: 12 }}>
          Session Stats
        </Text>
        <View
          style={{
            flexDirection: 'row',
            backgroundColor: '#2d3748',
            borderRadius: 12,
            padding: 16,
          }}
        >
          <StatBox label="Avg Speed" value={session.stats.avgSpeedMph || '--'} unit="mph" />
          <StatBox label="Rev Rate" value={session.stats.avgRevRateRpm || '--'} unit="rpm" />
          <StatBox label="Entry Angle" value={session.stats.avgEntryAngle || '--'} unit="°" />
          <StatBox label="Strike %" value={session.stats.strikeRate || '--'} unit="%" />
        </View>
      </View>

      {/* Shots list */}
      <View style={{ flex: 1, paddingHorizontal: 16 }}>
        <Text style={{ color: '#fff', fontSize: 16, fontWeight: '600', marginBottom: 12 }}>
          Shots
        </Text>

        {session.shots.length === 0 ? (
          <View
            style={{
              flex: 1,
              backgroundColor: '#2d3748',
              borderRadius: 12,
              justifyContent: 'center',
              alignItems: 'center',
              padding: 24,
            }}
          >
            <Text style={{ fontSize: 48, marginBottom: 12 }}>🎳</Text>
            <Text style={{ color: '#718096', textAlign: 'center' }}>
              No shots recorded in this session
            </Text>
          </View>
        ) : (
          <FlatList
            data={session.shots}
            keyExtractor={(item) => item.id}
            renderItem={({ item }) => (
              <Link href={`/shot/${item.id}`} asChild>
                <Pressable
                  style={{
                    backgroundColor: '#2d3748',
                    padding: 16,
                    borderRadius: 12,
                    marginBottom: 8,
                    flexDirection: 'row',
                    alignItems: 'center',
                  }}
                >
                  <View
                    style={{
                      width: 40,
                      height: 40,
                      borderRadius: 20,
                      backgroundColor: '#319795',
                      justifyContent: 'center',
                      alignItems: 'center',
                      marginRight: 12,
                    }}
                  >
                    <Text style={{ color: '#fff', fontWeight: 'bold' }}>
                      {item.shotNumber}
                    </Text>
                  </View>
                  <View style={{ flex: 1, flexDirection: 'row', justifyContent: 'space-between' }}>
                    <View>
                      <Text style={{ color: '#fff' }}>{item.speedMph} mph</Text>
                      <Text style={{ color: '#718096', fontSize: 12 }}>Speed</Text>
                    </View>
                    <View>
                      <Text style={{ color: '#fff' }}>{item.revRateRpm} rpm</Text>
                      <Text style={{ color: '#718096', fontSize: 12 }}>Rev Rate</Text>
                    </View>
                    <View>
                      <Text style={{ color: '#fff' }}>{item.entryAngleDeg}°</Text>
                      <Text style={{ color: '#718096', fontSize: 12 }}>Angle</Text>
                    </View>
                    <View>
                      <Text style={{ color: item.result === 'strike' ? '#48bb78' : '#fff' }}>
                        {item.result}
                      </Text>
                    </View>
                  </View>
                </Pressable>
              </Link>
            )}
          />
        )}
      </View>
    </SafeAreaView>
  );
}

function StatBox({ label, value, unit }: { label: string; value: string | number; unit: string }) {
  return (
    <View style={{ flex: 1, alignItems: 'center' }}>
      <Text style={{ color: '#718096', fontSize: 12, marginBottom: 4 }}>{label}</Text>
      <View style={{ flexDirection: 'row', alignItems: 'baseline' }}>
        <Text style={{ color: '#fff', fontSize: 18, fontWeight: 'bold' }}>{value}</Text>
        <Text style={{ color: '#718096', fontSize: 10, marginLeft: 2 }}>{unit}</Text>
      </View>
    </View>
  );
}
