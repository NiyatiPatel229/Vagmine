# Vagmine - Communication & Learning App for Disable People

## Overview
Vagmine is a comprehensive Flutter application designed to assist users with communication and learning needs. The app combines social networking features with educational tools, making it particularly useful for individuals with diverse communication requirements.

## Features

### 1. Text to Speech
- Convert written text to spoken words
- Adjustable speech parameters (pitch, rate, volume)
- User-friendly interface for text input

### 2. Speech to Text
- Real-time voice recognition
- Confidence level indication
- Easy-to-use microphone interface

### 3. Social Network
- Image sharing capabilities
- Profile customization
- Chat functionality
- Interactive feed with likes and comments
- User-friendly post management

### 4. Sign Language Tutorials
- Visual sign language demonstrations
- Comprehensive tutorial library
- Interactive quiz system
- Progress tracking
- Multiple difficulty levels

### 5. Autism-based Quiz
- Progressive level system
- Interactive learning modules
- Visual feedback system
- Adaptive difficulty
- Achievement tracking

## Technical Details

### Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  image_picker: ^0.8.7+5
  shared_preferences: ^2.2.1
  path_provider: ^2.1.1
  path: ^1.8.3
  intl: ^0.18.1
  flutter_tts: ^latest_version
  speech_to_text: ^latest_version
```

### Platform Support
- iOS
- Android
- Web (partial support)

## Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/vagmine.git
```

2. Install dependencies
```bash
flutter pub get
```

3. Run the app
```bash
flutter run
```

## Configuration

### Android Setup
Add these permissions to your AndroidManifest.xml:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

### iOS Setup
Add these permissions to your Info.plist:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs access to microphone for speech recognition</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to photos for sharing images</string>
```

## Acknowledgments
- Flutter team for the amazing framework
- Contributors and testers
- Open source community

---
Made with ❤️ using Flutter
