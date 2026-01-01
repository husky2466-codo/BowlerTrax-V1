import { useState } from 'react';
import { View, Text, Pressable, StyleSheet } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { CameraView, useCameraPermissions } from 'expo-camera';
import { router } from 'expo-router';

type CalibrationStep = 'position' | 'foul_line' | 'arrows' | 'verify' | 'complete';

const STEPS = [
  { id: 'position', title: 'Position Camera', description: 'Place camera behind bowler, elevated 5-6 feet' },
  { id: 'foul_line', title: 'Mark Foul Line', description: 'Tap on the foul line in the camera view' },
  { id: 'arrows', title: 'Mark Arrows', description: 'Tap on two arrows (they are 15ft from foul line)' },
  { id: 'verify', title: 'Verify', description: 'Check that the overlay matches the lane' },
  { id: 'complete', title: 'Done!', description: 'Calibration saved' },
];

export default function CalibrateScreen() {
  const [permission, requestPermission] = useCameraPermissions();
  const [currentStep, setCurrentStep] = useState<CalibrationStep>('position');
  const [foulLineY, setFoulLineY] = useState<number | null>(null);
  const [arrowPoints, setArrowPoints] = useState<{ x: number; y: number }[]>([]);

  const stepIndex = STEPS.findIndex((s) => s.id === currentStep);
  const currentStepInfo = STEPS[stepIndex];

  // Permission handling
  if (!permission) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.centered}>
          <Text style={styles.message}>Loading camera...</Text>
        </View>
      </SafeAreaView>
    );
  }

  if (!permission.granted) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.centered}>
          <Text style={styles.title}>Camera Access Required</Text>
          <Text style={styles.message}>Camera access is needed to calibrate the lane.</Text>
          <Pressable style={styles.primaryButton} onPress={requestPermission}>
            <Text style={styles.buttonText}>Grant Permission</Text>
          </Pressable>
        </View>
      </SafeAreaView>
    );
  }

  const handleNext = () => {
    const nextIndex = stepIndex + 1;
    if (nextIndex < STEPS.length) {
      setCurrentStep(STEPS[nextIndex].id as CalibrationStep);
    } else {
      // Save and close
      router.back();
    }
  };

  const handleBack = () => {
    const prevIndex = stepIndex - 1;
    if (prevIndex >= 0) {
      setCurrentStep(STEPS[prevIndex].id as CalibrationStep);
    } else {
      router.back();
    }
  };

  const handleTapCamera = (event: any) => {
    const { locationX, locationY } = event.nativeEvent;

    if (currentStep === 'foul_line') {
      setFoulLineY(locationY);
      handleNext();
    } else if (currentStep === 'arrows') {
      const newPoints = [...arrowPoints, { x: locationX, y: locationY }];
      setArrowPoints(newPoints);
      if (newPoints.length >= 2) {
        handleNext();
      }
    }
  };

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      {/* Progress indicator */}
      <View style={styles.progressBar}>
        {STEPS.map((step, index) => (
          <View
            key={step.id}
            style={[
              styles.progressDot,
              index <= stepIndex && styles.progressDotActive,
            ]}
          />
        ))}
      </View>

      {/* Step info */}
      <View style={styles.stepInfo}>
        <Text style={styles.stepTitle}>{currentStepInfo.title}</Text>
        <Text style={styles.stepDescription}>{currentStepInfo.description}</Text>
      </View>

      {/* Camera view */}
      <View style={styles.cameraContainer}>
        <CameraView style={styles.camera} facing="back">
          <Pressable style={styles.tapArea} onPress={handleTapCamera}>
            {/* Overlay markers */}
            {foulLineY !== null && (
              <View
                style={[
                  styles.horizontalLine,
                  { top: foulLineY },
                ]}
              />
            )}
            {arrowPoints.map((point, index) => (
              <View
                key={index}
                style={[
                  styles.marker,
                  { left: point.x - 10, top: point.y - 10 },
                ]}
              />
            ))}

            {/* Instruction overlay */}
            {currentStep === 'foul_line' && (
              <Text style={styles.instructionOverlay}>
                Tap on the foul line
              </Text>
            )}
            {currentStep === 'arrows' && (
              <Text style={styles.instructionOverlay}>
                Tap on arrow {arrowPoints.length + 1} of 2
              </Text>
            )}
          </Pressable>
        </CameraView>
      </View>

      {/* Bottom controls */}
      <View style={styles.controls}>
        <Pressable style={styles.secondaryButton} onPress={handleBack}>
          <Text style={styles.secondaryButtonText}>
            {stepIndex === 0 ? 'Cancel' : 'Back'}
          </Text>
        </Pressable>

        {currentStep === 'position' || currentStep === 'verify' ? (
          <Pressable style={styles.primaryButton} onPress={handleNext}>
            <Text style={styles.buttonText}>
              {currentStep === 'verify' ? 'Save Calibration' : 'Next'}
            </Text>
          </Pressable>
        ) : currentStep === 'complete' ? (
          <Pressable style={styles.primaryButton} onPress={() => router.back()}>
            <Text style={styles.buttonText}>Done</Text>
          </Pressable>
        ) : null}
      </View>
    </SafeAreaView>
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
  progressBar: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 8,
    padding: 16,
  },
  progressDot: {
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: '#4a5568',
  },
  progressDotActive: {
    backgroundColor: '#4fd1c5',
  },
  stepInfo: {
    padding: 16,
    alignItems: 'center',
  },
  stepTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#fff',
    marginBottom: 4,
  },
  stepDescription: {
    color: '#718096',
    textAlign: 'center',
  },
  cameraContainer: {
    flex: 1,
    margin: 16,
    borderRadius: 12,
    overflow: 'hidden',
  },
  camera: {
    flex: 1,
  },
  tapArea: {
    flex: 1,
  },
  horizontalLine: {
    position: 'absolute',
    left: 0,
    right: 0,
    height: 3,
    backgroundColor: '#4fd1c5',
  },
  marker: {
    position: 'absolute',
    width: 20,
    height: 20,
    borderRadius: 10,
    backgroundColor: '#f56565',
    borderWidth: 2,
    borderColor: '#fff',
  },
  instructionOverlay: {
    position: 'absolute',
    bottom: 20,
    left: 0,
    right: 0,
    textAlign: 'center',
    color: '#fff',
    fontSize: 18,
    fontWeight: 'bold',
    backgroundColor: 'rgba(0, 0, 0, 0.7)',
    padding: 12,
  },
  controls: {
    flexDirection: 'row',
    gap: 12,
    padding: 16,
    backgroundColor: '#1a202c',
  },
  primaryButton: {
    flex: 1,
    backgroundColor: '#319795',
    padding: 16,
    borderRadius: 12,
    alignItems: 'center',
  },
  secondaryButton: {
    flex: 1,
    backgroundColor: '#4a5568',
    padding: 16,
    borderRadius: 12,
    alignItems: 'center',
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold',
  },
  secondaryButtonText: {
    color: '#fff',
    fontSize: 16,
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
