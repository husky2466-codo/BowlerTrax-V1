#!/usr/bin/env python3
"""
Video Analysis Script for LaneTrax App Study
Extracts frames and transcribes audio from YouTube review videos
"""

import os
import sys
import cv2
import whisper
import numpy as np
from pathlib import Path
import json
from datetime import timedelta
import subprocess
import imageio_ffmpeg
import wave

# Paths
BASE_DIR = Path("D:/Projects/BowlerTrax")
VIDEOS_DIR = BASE_DIR / "Videos"
ANALYSIS_DIR = BASE_DIR / "Analysis"
FRAMES_DIR = ANALYSIS_DIR / "frames"
TRANSCRIPTS_DIR = ANALYSIS_DIR / "transcripts"

# Video files
VIDEOS = [
    {
        "name": "video1_zvl_rev_rate",
        "file": "FIND YOUR REV RATE AND GET VIDEOS! Lanetrax MAJOR Update! - ZVL Bowling (1080p, h264, youtube).mp4",
        "title": "ZVL Bowling - Find Your Rev Rate (LaneTrax Major Update)"
    },
    {
        "name": "video2_joshua_review",
        "file": "LaneTrax Bowling App Review  Setup, Features & How It Works - Joshua Tajiri Bowling (1080p, h264, youtube).mp4",
        "title": "Joshua Tajiri - LaneTrax App Review, Setup & Features"
    },
    {
        "name": "video3_zvl_specto",
        "file": "SPECTO AS AN APP Lanetrax - Find Your Rev Rate and Speed Easily! - ZVL Bowling (1080p, h264, youtube).mp4",
        "title": "ZVL Bowling - Specto as an App (LaneTrax)"
    }
]


def load_audio_from_wav(file_path: str, sr: int = 16000) -> np.ndarray:
    """Load audio from a WAV file as numpy array for Whisper"""
    with wave.open(file_path, 'rb') as wav:
        frames = wav.readframes(wav.getnframes())
        audio = np.frombuffer(frames, dtype=np.int16).astype(np.float32) / 32768.0
    return audio


def extract_audio(video_path: Path, output_path: Path) -> Path:
    """Extract audio from video to WAV file for Whisper"""
    ffmpeg_exe = imageio_ffmpeg.get_ffmpeg_exe()
    audio_file = output_path / f"{video_path.stem}.wav"

    if audio_file.exists():
        print(f"  Audio file already exists: {audio_file.name}")
        return audio_file

    print(f"  Extracting audio to: {audio_file.name}")
    cmd = [
        ffmpeg_exe,
        "-i", str(video_path),
        "-vn",  # No video
        "-acodec", "pcm_s16le",  # PCM 16-bit
        "-ar", "16000",  # 16kHz sample rate (Whisper expects this)
        "-ac", "1",  # Mono
        "-y",  # Overwrite
        str(audio_file)
    ]

    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"  ERROR extracting audio: {result.stderr}")
        return None

    return audio_file


def extract_frames(video_path: Path, output_dir: Path, fps_sample: float = 0.5):
    """
    Extract frames from video at specified sample rate
    fps_sample: frames per second to extract (0.5 = 1 frame every 2 seconds)
    """
    print(f"\nExtracting frames from: {video_path.name}")

    cap = cv2.VideoCapture(str(video_path))
    if not cap.isOpened():
        print(f"  ERROR: Could not open video")
        return []

    fps = cap.get(cv2.CAP_PROP_FPS)
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    duration = total_frames / fps

    print(f"  Video FPS: {fps:.2f}, Duration: {duration:.1f}s, Total frames: {total_frames}")

    # Calculate frame interval
    frame_interval = int(fps / fps_sample)

    output_dir.mkdir(parents=True, exist_ok=True)

    frame_count = 0
    saved_count = 0
    extracted_frames = []

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        if frame_count % frame_interval == 0:
            timestamp = frame_count / fps
            filename = f"frame_{saved_count:04d}_t{timestamp:.1f}s.jpg"
            filepath = output_dir / filename

            # Resize to reasonable size for analysis
            height, width = frame.shape[:2]
            if width > 1280:
                scale = 1280 / width
                frame = cv2.resize(frame, (int(width * scale), int(height * scale)))

            cv2.imwrite(str(filepath), frame, [cv2.IMWRITE_JPEG_QUALITY, 85])
            extracted_frames.append({
                "filename": filename,
                "timestamp": timestamp,
                "frame_number": frame_count
            })
            saved_count += 1

            if saved_count % 50 == 0:
                print(f"  Extracted {saved_count} frames...")

        frame_count += 1

    cap.release()
    print(f"  Completed: {saved_count} frames extracted")

    # Save frame index
    index_file = output_dir / "frame_index.json"
    with open(index_file, "w", encoding="utf-8") as f:
        json.dump(extracted_frames, f, indent=2)

    return extracted_frames


def transcribe_audio(audio_path: Path, output_dir: Path, model_name: str = "base"):
    """
    Transcribe audio file using Whisper
    """
    print(f"\nTranscribing: {audio_path.name}")

    # Load whisper model
    print(f"  Loading Whisper model '{model_name}'...")
    model = whisper.load_model(model_name)

    # Load audio directly from WAV file
    print(f"  Loading audio from WAV file...")
    audio = load_audio_from_wav(str(audio_path))

    print(f"  Transcribing audio (this may take a while)...")
    result = model.transcribe(audio, verbose=False)

    # Save full transcript as readable text
    transcript_file = output_dir / f"{audio_path.stem}_transcript.txt"
    with open(transcript_file, "w", encoding="utf-8") as f:
        f.write(f"# Transcript: {audio_path.stem}\n\n")
        for segment in result["segments"]:
            start = str(timedelta(seconds=int(segment["start"])))
            end = str(timedelta(seconds=int(segment["end"])))
            text = segment["text"].strip()
            f.write(f"[{start} - {end}] {text}\n")

    # Save JSON with segments for analysis
    json_file = output_dir / f"{audio_path.stem}_transcript.json"
    with open(json_file, "w", encoding="utf-8") as f:
        json.dump({
            "text": result["text"],
            "segments": [
                {
                    "start": seg["start"],
                    "end": seg["end"],
                    "text": seg["text"].strip()
                }
                for seg in result["segments"]
            ]
        }, f, indent=2)

    print(f"  Saved transcript to: {transcript_file.name}")
    print(f"  Full text length: {len(result['text'])} characters")
    print(f"  Segments: {len(result['segments'])}")

    return result


def main():
    print("=" * 60)
    print("LaneTrax Video Analysis - Frame Extraction & Transcription")
    print("=" * 60)

    # Check ffmpeg
    ffmpeg_exe = imageio_ffmpeg.get_ffmpeg_exe()
    print(f"\nUsing ffmpeg from: {ffmpeg_exe}")

    results = {}
    TRANSCRIPTS_DIR.mkdir(parents=True, exist_ok=True)

    for i, video_info in enumerate(VIDEOS, 1):
        print(f"\n{'='*60}")
        print(f"Processing Video {i}/3: {video_info['title']}")
        print("=" * 60)

        video_path = VIDEOS_DIR / video_info["file"]

        if not video_path.exists():
            print(f"  ERROR: Video file not found: {video_path}")
            continue

        video_name = video_info["name"]
        frames_output = FRAMES_DIR / video_name

        # Extract frames (1 frame every 2 seconds)
        frames = extract_frames(video_path, frames_output, fps_sample=0.5)

        # Extract audio first
        audio_file = extract_audio(video_path, TRANSCRIPTS_DIR)

        if audio_file and audio_file.exists():
            # Transcribe audio
            transcript = transcribe_audio(audio_file, TRANSCRIPTS_DIR)

            results[video_name] = {
                "title": video_info["title"],
                "frames_extracted": len(frames),
                "frames_dir": str(frames_output),
                "transcript_length": len(transcript["text"]),
                "segments_count": len(transcript["segments"])
            }
        else:
            results[video_name] = {
                "title": video_info["title"],
                "frames_extracted": len(frames),
                "frames_dir": str(frames_output),
                "transcript_length": 0,
                "segments_count": 0,
                "error": "Audio extraction failed"
            }

    # Save summary
    summary_file = ANALYSIS_DIR / "analysis_summary.json"
    with open(summary_file, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2)

    print("\n" + "=" * 60)
    print("ANALYSIS COMPLETE")
    print("=" * 60)
    for name, data in results.items():
        print(f"\n{data['title']}:")
        print(f"  - Frames: {data['frames_extracted']}")
        print(f"  - Transcript segments: {data.get('segments_count', 'N/A')}")


if __name__ == "__main__":
    main()
