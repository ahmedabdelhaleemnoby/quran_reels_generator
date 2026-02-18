---
description: How to run Flutter and Pod commands in this project
---

Because your `flutter` command is not in the system path, use these absolute paths:

### 1. Run Flutter Analyze
// turbo
```bash
/Users/ahmedabuzyad/Desktop/flutter/flutter/bin/flutter analyze
```

### 2. Run the App (iOS Simulator)
// turbo
```bash
/Users/ahmedabuzyad/Desktop/flutter/flutter/bin/flutter run
```

### 3. Update CocoaPods
// turbo
```bash
cd ios && pod install && cd ..
```

### 4. Clean Project
// turbo
```bash
/Users/ahmedabuzyad/Desktop/flutter/flutter/bin/flutter clean
```
