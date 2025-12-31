import { View, Text, FlatList, Pressable } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Link } from 'expo-router';

// Placeholder data type
interface SessionItem {
  id: string;
  date: string;
  centerName: string;
  shotCount: number;
  strikeCount: number;
  avgSpeed: number;
  avgRevRate: number;
}

// Placeholder empty state
const sessions: SessionItem[] = [];

export default function SessionsScreen() {
  if (sessions.length === 0) {
    return (
      <SafeAreaView style={{ flex: 1, backgroundColor: '#1a1a1a' }} edges={['left', 'right']}>
        <View
          style={{
            flex: 1,
            justifyContent: 'center',
            alignItems: 'center',
            padding: 24,
          }}
        >
          <Text style={{ fontSize: 64, marginBottom: 16 }}>🎳</Text>
          <Text
            style={{
              fontSize: 20,
              fontWeight: 'bold',
              color: '#fff',
              marginBottom: 8,
            }}
          >
            No Sessions Yet
          </Text>
          <Text
            style={{
              color: '#718096',
              textAlign: 'center',
              marginBottom: 24,
            }}
          >
            Start recording your bowling sessions to track your progress over time.
          </Text>
          <Link href="/record" asChild>
            <Pressable
              style={{
                backgroundColor: '#319795',
                paddingHorizontal: 24,
                paddingVertical: 12,
                borderRadius: 8,
              }}
            >
              <Text style={{ color: '#fff', fontWeight: 'bold', fontSize: 16 }}>
                Record First Session
              </Text>
            </Pressable>
          </Link>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: '#1a1a1a' }} edges={['left', 'right']}>
      <FlatList
        data={sessions}
        keyExtractor={(item) => item.id}
        contentContainerStyle={{ padding: 16 }}
        renderItem={({ item }) => (
          <Link href={`/session/${item.id}`} asChild>
            <Pressable
              style={{
                backgroundColor: '#2d3748',
                padding: 16,
                borderRadius: 12,
                marginBottom: 12,
              }}
            >
              <View
                style={{
                  flexDirection: 'row',
                  justifyContent: 'space-between',
                  marginBottom: 8,
                }}
              >
                <Text style={{ color: '#fff', fontWeight: 'bold', fontSize: 16 }}>
                  {item.centerName}
                </Text>
                <Text style={{ color: '#718096' }}>{item.date}</Text>
              </View>

              <View style={{ flexDirection: 'row', gap: 16 }}>
                <View>
                  <Text style={{ color: '#718096', fontSize: 12 }}>Shots</Text>
                  <Text style={{ color: '#fff', fontWeight: '600' }}>{item.shotCount}</Text>
                </View>
                <View>
                  <Text style={{ color: '#718096', fontSize: 12 }}>Strikes</Text>
                  <Text style={{ color: '#fff', fontWeight: '600' }}>{item.strikeCount}</Text>
                </View>
                <View>
                  <Text style={{ color: '#718096', fontSize: 12 }}>Avg Speed</Text>
                  <Text style={{ color: '#fff', fontWeight: '600' }}>{item.avgSpeed} mph</Text>
                </View>
                <View>
                  <Text style={{ color: '#718096', fontSize: 12 }}>Rev Rate</Text>
                  <Text style={{ color: '#fff', fontWeight: '600' }}>{item.avgRevRate} rpm</Text>
                </View>
              </View>
            </Pressable>
          </Link>
        )}
      />
    </SafeAreaView>
  );
}
