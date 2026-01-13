# EchoPaint: The "Invisible" Canvas

**An accessibility-focused drawing app that lets blind users "see" their art through sound and touch.**

## 🎨 Concept

EchoPaint transforms visual art into an audio-spatial experience. Instead of relying on sight, users create and perceive their artwork through:

- **Sonification**: Continuous tones mapped to screen position
- **Haptic Feedback**: Tactile textures when touching drawn lines

## 🔊 How It Works

### Audio-Spatial Mapping

| Screen Position | Audio Effect |
|-----------------|--------------|
| **Vertical (Y-axis)** | Pitch: 200Hz (bottom) → 2000Hz (top) |
| **Horizontal (X-axis)** | Stereo pan: Left ear → Right ear |
| **Over existing line** | Timbre changes from sine to sawtooth wave |
| **Shape closed** | 🎵 **Smart Fill**: Resonant chord plays when you close a shape |

### Haptic Feedback

| Context | Feeling |
|---------|---------|
| Drawing on empty canvas | Gentle continuous vibration |
| Crossing existing line | Sharp "bump" texture |
| **Shape closed** | 🌸 Celebratory "bloom" pattern |

## ♿ Accessibility Features

Built following Apple's **Human Interface Guidelines** for Accessibility:

- ✅ Full VoiceOver support with descriptive labels
- ✅ Accessibility traits (`.allowsDirectInteraction` for canvas)
- ✅ Dynamic announcements for state changes
- ✅ Respects `reduceMotion` preference
- ✅ High contrast UI (white on black)

## 🛠 Technical Stack

- **SwiftUI** - Modern declarative UI
- **AVAudioEngine** - Low-latency audio synthesis
- **CoreHaptics** - Advanced haptic patterns
- **UIKit** (via `UIViewRepresentable`) - Custom touch handling

## 📱 Requirements

- iOS 17.0+
- Physical iPhone (CoreHaptics requires real device)
- Headphones recommended for stereo effect

## 🚀 Getting Started

1. Open `EchoPaint` folder in **Swift Playgrounds** or **Xcode**
2. Build and run on a **physical iPhone**
3. Put on headphones
4. Touch the black canvas and start drawing!

## 🏆 Swift Student Challenge

This app demonstrates:
- Deep understanding of audio-spatial mapping
- Proper implementation of CoreHaptics patterns
- Adherence to Apple's Accessibility HIG
- Creative reimagination of "Visual Arts"

---

*Created for Swift Student Challenge 2026*
