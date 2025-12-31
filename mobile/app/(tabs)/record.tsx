import { useState, useRef, useEffect } from 'react';
import { View, Text, Pressable, StyleSheet, Alert } from 'react-native';
import { CameraView, useCameraPermissions } from 'expo-camera';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Link } from 'expo-router';

export default function RecordScreen() {
  const [permission, requestPermission] = useCameraPermissions();
  const [isRecording, setIsRecording] = useState(false);
  const [shotCount, setShotCount] = useState(0);
  const cameraRef = useRef<CameraView>(null);

  // Permission not determined yet
  if (!permission) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.centered}>
          <Text style={styles.message}>Loading camera...</Text>
        </View>
      </SafeAreaView>
    );
  }

  // Permission denied
  if (!permission.granted) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.centered}>
          <Text style={styles.title}>Camera Access Required</Text>
          <Text style={styles.message}>
            BowlerTrax needs camera access to track your bowling shots.
          </Text>
          <Pressable style={styles.primaryButton} onPress={requestPermission}>
            <Text style={styles.buttonText}>Grant Permission</Text>
          </Pressable>
        </View>
      </SafeAreaView>
    );
  }

  const handleStartSession = () => {
    setIsRecording(true);
    setShotCount(0);
  };

  const handleEndSession = () => {
    if (shotCount > 0) {
      Alert.alert(
        'End Session',
        `Save this session with ${shotCount} shots?`,
        [
          { text: 'Cancel', style: 'cancel' },
          {
            text: 'Save & End',
            onPress: () => {
              setIsRecording(false);
              setShotCount(0);
              // TODO: Save session to database
            },
          },
          {
            text: 'Discard',
            style: 'destructive',
            onPress: () => {
              setIsRecording(false);
              setShotCount(0);
            },
          },
        ]
      );
    } else {
      setIsRecording(false);
    }
  };

  return (
    <SafeAreaView style={styles.container} edges={['left', 'right']}>
      <View style={styles.cameraContainer}>
        <CameraView
          ref={cameraRef}
          style={styles.camera}
          facing="back"
        >
          {/* Overlay guides */}
          <View style={styles.overlay}>
            {/* Lane guide lines */}
            <View style={styles.laneGuide}>
              <View style={styles.foulLine} />
              <View style={styles.arrowLine} />
            </View>

            {/* Top info bar */}
            <View style={styles.topBar}>
              {isRecording ? (
                <>
                  <View style={styles.recordingIndicator}>
                    <View style={styles.recordDot} />
                    <Text style={styles.recordingText}>TRACKING</Text>
                  </View>
                  <Text style={styles.shotCounter}>Shots: {shotCount}</Text>
                </>
              ) : (
                <Text style={styles.helperText}>
                  Position camera behind bowler, elevated
                </Text>
              )}
            </View>

            {/* Calibration warning if not calibrated */}
            {!isRecording && (
              <View style={styles.warningBanner}>
                <Text style={styles.warningText}>
                  ⚠️ Lane not calibrated
                </Text>
                <Link href="/calibrate" asChild>
                  <Pressable>
                    <Text style={styles.linkText}>Calibrate Now</Text>
                  </Pressable>
                </Link>
              </View>
            )}
          </View>
        </CameraView>
      </View>

      {/* Bottom controls */}
      <View style={styles.controls}>
        {isRecording ? (
          <>
            {/* Placeholder metrics display */}
            <View style={styles.metricsRow}>
              <MetricBadge label="Speed" value="--" unit="mph" />
              <MetricBadge label="Rev Rate" value="--" unit="rpm" />
              <MetricBadge label="Angle" value="--" unit="°" />
            </View>

            <View style={styles.buttonRow}>
              <Pressable
                style={styles.endButton}
                onPress={handleEndSession}
              >
                <Text style={styles.buttonText}>End Session</Text>
              </Pressable>
            </View>
          </>
        ) : (
          <View style={styles.buttonRow}>
            <Pressable
              style={styles.primaryButton}
              onPress={handleStartSession}
            >
              <Text style={styles.buttonText}>Start Recording</Text>
            </Pressable>
          </View>
        )}
      </View>
    </SafeAreaView>
  );
}

function MetricBadge({ label, value, unit }: { label: string; value: string; unit: string }) {
  return (
    <View style={styles.metricBadge}>
      <Text style={styles.metricLabel}>{label}</Text>
      <View style={{ flexDirection: 'row', alignItems: 'baseline' }}>
        <Text style={styles.metricValue}>{value}</Text>
        <Text style={styles.metricUnit}>{unit}</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#1a1a1a',
  },
  centered: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 24,
  },
  cameraContainer: {
    flex: 1,
    overflow: 'hidden',
  },
  camera: {
    flex: 1,
  },
  overlay: {
    flex: 1,
  },
  laneGuide: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
  },
  foulLine: {
    position: 'absolute',
    bottom: '20%',
    left: 0,
    right: 0,
    height: 2,
    backgroundColor: 'rgba(79, 209, 197, 0.5)',
  },
  arrowLine: {
    position: 'absolute',
    bottom: '40%',
    left: 0,
    right: 0,
    height: 2,
    backgroundColor: 'rgba(79, 209, 197, 0.3)',
  },
  topBar: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 16,
    paddingTop: 48,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
  },
  recordingIndicator: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  recordDot: {
    width: 12,
    height: 12,
    borderRadius: 6,
    backgroundColor: '#ef4444',
  },
  recordingText: {
    color: '#fff',
    fontWeight: 'bold',
  },
  shotCounter: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  helperText: {
    color: '#a0aec0',
    fontSize: 14,
  },
  warningBanner: {
    position: 'absolute',
    bottom: 20,
    left: 20,
    right: 20,
    backgroundColor: 'rgba(237, 137, 54, 0.9)',
    padding: 12,
    borderRadius: 8,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  warningText: {
    color: '#fff',
    fontWeight: '600',
  },
  linkText: {
    color: '#fff',
    textDecorationLine: 'underline',
  },
  controls: {
    backgroundColor: '#1a202c',
    padding: 16,
    borderTopWidth: 1,
    borderTopColor: '#2d3748',
  },
  metricsRow: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    marginBottom: 16,
  },
  metricBadge: {
    alignItems: 'center',
    backgroundColor: '#2d3748',
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 8,
    minWidth: 80,
  },
  metricLabel: {
    color: '#718096',
    fontSize: 12,
  },
  metricValue: {
    color: '#fff',
    fontSize: 20,
    fontWeight: 'bold',
  },
  metricUnit: {
    color: '#718096',
    fontSize: 12,
    marginLeft: 2,
  },
  buttonRow: {
    flexDirection: 'row',
    gap: 12,
  },
  primaryButton: {
    flex: 1,
    backgroundColor: '#319795',
    padding: 16,
    borderRadius: 12,
    alignItems: 'center',
  },
  endButton: {
    flex: 1,
    backgroundColor: '#e53e3e',
    padding: 16,
    borderRadius: 12,
    alignItems: 'center',
  },
  buttonText: {
    color: '#fff',
    fontSize: 18,
    fontWeight: 'bold',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#fff',
    marginBottom: 12,
  },
  message: {
    color: '#718096',
    fontSize: 16,
    textAlign: 'center',
    marginBottom: 24,
  },
});
