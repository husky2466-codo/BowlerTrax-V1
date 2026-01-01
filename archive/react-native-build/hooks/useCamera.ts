/**
 * useCamera Hook
 * Camera access, permissions, and frame capture
 */

import { useState, useCallback, useRef } from 'react';
import { CameraView, useCameraPermissions } from 'expo-camera';

export interface UseCameraReturn {
  /** Camera permission status */
  permission: ReturnType<typeof useCameraPermissions>[0];
  /** Request camera permission */
  requestPermission: () => Promise<void>;
  /** Is camera ready */
  isReady: boolean;
  /** Set camera ready state */
  setReady: (ready: boolean) => void;
  /** Camera ref for direct access */
  cameraRef: React.RefObject<CameraView | null>;
}

export function useCamera(): UseCameraReturn {
  const [permission, requestPermissionAsync] = useCameraPermissions();
  const [isReady, setReady] = useState(false);
  const cameraRef = useRef<CameraView>(null);

  const requestPermission = useCallback(async () => {
    await requestPermissionAsync();
  }, [requestPermissionAsync]);

  return {
    permission,
    requestPermission,
    isReady,
    setReady,
    cameraRef,
  };
}
