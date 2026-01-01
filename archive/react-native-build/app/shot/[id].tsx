import { View, Text, ScrollView } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useLocalSearchParams } from 'expo-router';

export default function ShotDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();

  // Placeholder data - would come from database
  const shot = {
    id,
    shotNumber: 1,
    speedMph: 17.5,
    impactSpeedMph: 16.2,
    revRateRpm: 350,
    revCategory: 'tweener',
    entryAngleDeg: 5.8,
    launchAngleDeg: 3.2,
    foulLineBoard: 20,
    arrowBoard: 15,
    breakpointBoard: 8,
    breakpointDistanceFt: 42,
    pocketOffsetBoards: 0.3,
    strikeProbability: 0.85,
    predictedLeave: 'clean',
    actualResult: 'strike',
  };

  const getStrikeProbabilityColor = (prob: number) => {
    if (prob >= 0.8) return '#48bb78';
    if (prob >= 0.5) return '#ed8936';
    return '#f56565';
  };

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: '#1a1a1a' }} edges={['left', 'right']}>
      <ScrollView contentContainerStyle={{ padding: 16 }}>
        {/* Shot header */}
        <View
          style={{
            backgroundColor: '#2d3748',
            borderRadius: 12,
            padding: 16,
            marginBottom: 16,
            alignItems: 'center',
          }}
        >
          <View
            style={{
              width: 60,
              height: 60,
              borderRadius: 30,
              backgroundColor: shot.actualResult === 'strike' ? '#48bb78' : '#319795',
              justifyContent: 'center',
              alignItems: 'center',
              marginBottom: 8,
            }}
          >
            <Text style={{ color: '#fff', fontSize: 24, fontWeight: 'bold' }}>
              {shot.shotNumber}
            </Text>
          </View>
          <Text style={{ color: '#fff', fontSize: 20, fontWeight: 'bold' }}>
            {shot.actualResult === 'strike' ? 'Strike!' : shot.actualResult.toUpperCase()}
          </Text>
        </View>

        {/* Trajectory placeholder */}
        <View style={{ marginBottom: 16 }}>
          <Text style={{ color: '#fff', fontSize: 16, fontWeight: '600', marginBottom: 8 }}>
            Trajectory
          </Text>
          <View
            style={{
              backgroundColor: '#2d3748',
              borderRadius: 12,
              height: 200,
              justifyContent: 'center',
              alignItems: 'center',
            }}
          >
            <Text style={{ color: '#718096' }}>
              Trajectory visualization will appear here
            </Text>
          </View>
        </View>

        {/* Strike probability */}
        <View style={{ marginBottom: 16 }}>
          <Text style={{ color: '#fff', fontSize: 16, fontWeight: '600', marginBottom: 8 }}>
            Strike Analysis
          </Text>
          <View
            style={{
              backgroundColor: '#2d3748',
              borderRadius: 12,
              padding: 16,
            }}
          >
            <View style={{ alignItems: 'center', marginBottom: 16 }}>
              <Text style={{ color: '#718096', marginBottom: 4 }}>Strike Probability</Text>
              <Text
                style={{
                  fontSize: 48,
                  fontWeight: 'bold',
                  color: getStrikeProbabilityColor(shot.strikeProbability),
                }}
              >
                {Math.round(shot.strikeProbability * 100)}%
              </Text>
              <Text style={{ color: '#718096' }}>
                Predicted: {shot.predictedLeave}
              </Text>
            </View>

            <View style={{ flexDirection: 'row', justifyContent: 'space-around' }}>
              <View style={{ alignItems: 'center' }}>
                <Text style={{ color: '#fff', fontSize: 20, fontWeight: 'bold' }}>
                  {shot.entryAngleDeg}°
                </Text>
                <Text style={{ color: '#718096', fontSize: 12 }}>Entry Angle</Text>
                <Text style={{ color: '#4fd1c5', fontSize: 10 }}>Optimal: 6°</Text>
              </View>
              <View style={{ alignItems: 'center' }}>
                <Text style={{ color: '#fff', fontSize: 20, fontWeight: 'bold' }}>
                  {shot.pocketOffsetBoards}
                </Text>
                <Text style={{ color: '#718096', fontSize: 12 }}>Pocket Offset</Text>
                <Text style={{ color: '#4fd1c5', fontSize: 10 }}>boards from 17.5</Text>
              </View>
            </View>
          </View>
        </View>

        {/* Speed & Rev Rate */}
        <View style={{ marginBottom: 16 }}>
          <Text style={{ color: '#fff', fontSize: 16, fontWeight: '600', marginBottom: 8 }}>
            Speed & Rev Rate
          </Text>
          <View
            style={{
              flexDirection: 'row',
              gap: 12,
            }}
          >
            <View style={{ flex: 1, backgroundColor: '#2d3748', borderRadius: 12, padding: 16 }}>
              <Text style={{ color: '#718096', marginBottom: 8 }}>Launch Speed</Text>
              <Text style={{ color: '#fff', fontSize: 28, fontWeight: 'bold' }}>
                {shot.speedMph}
                <Text style={{ fontSize: 14, color: '#718096' }}> mph</Text>
              </Text>
              <Text style={{ color: '#718096', fontSize: 12, marginTop: 4 }}>
                Impact: {shot.impactSpeedMph} mph
              </Text>
            </View>
            <View style={{ flex: 1, backgroundColor: '#2d3748', borderRadius: 12, padding: 16 }}>
              <Text style={{ color: '#718096', marginBottom: 8 }}>Rev Rate</Text>
              <Text style={{ color: '#fff', fontSize: 28, fontWeight: 'bold' }}>
                {shot.revRateRpm}
                <Text style={{ fontSize: 14, color: '#718096' }}> rpm</Text>
              </Text>
              <Text style={{ color: '#4fd1c5', fontSize: 12, marginTop: 4 }}>
                {shot.revCategory.charAt(0).toUpperCase() + shot.revCategory.slice(1)}
              </Text>
            </View>
          </View>
        </View>

        {/* Board positions */}
        <View style={{ marginBottom: 16 }}>
          <Text style={{ color: '#fff', fontSize: 16, fontWeight: '600', marginBottom: 8 }}>
            Board Positions
          </Text>
          <View style={{ backgroundColor: '#2d3748', borderRadius: 12, padding: 16 }}>
            <View style={{ flexDirection: 'row', justifyContent: 'space-between', marginBottom: 12 }}>
              <View>
                <Text style={{ color: '#718096', fontSize: 12 }}>Foul Line</Text>
                <Text style={{ color: '#fff', fontSize: 18, fontWeight: 'bold' }}>
                  Board {shot.foulLineBoard}
                </Text>
              </View>
              <View>
                <Text style={{ color: '#718096', fontSize: 12 }}>Arrows (15ft)</Text>
                <Text style={{ color: '#fff', fontSize: 18, fontWeight: 'bold' }}>
                  Board {shot.arrowBoard}
                </Text>
              </View>
              <View>
                <Text style={{ color: '#718096', fontSize: 12 }}>Breakpoint</Text>
                <Text style={{ color: '#fff', fontSize: 18, fontWeight: 'bold' }}>
                  Board {shot.breakpointBoard}
                </Text>
              </View>
            </View>
            <View style={{ flexDirection: 'row', justifyContent: 'space-between' }}>
              <View>
                <Text style={{ color: '#718096', fontSize: 12 }}>Launch Angle</Text>
                <Text style={{ color: '#fff', fontSize: 18, fontWeight: 'bold' }}>
                  {shot.launchAngleDeg}°
                </Text>
              </View>
              <View>
                <Text style={{ color: '#718096', fontSize: 12 }}>Breakpoint Distance</Text>
                <Text style={{ color: '#fff', fontSize: 18, fontWeight: 'bold' }}>
                  {shot.breakpointDistanceFt} ft
                </Text>
              </View>
            </View>
          </View>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}
