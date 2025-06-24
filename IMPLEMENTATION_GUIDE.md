# Implementation Guide

## Splash Screen Setup

### 1. Image Requirements
Place your splash screen image at: `assets/images/splashscreen.png`

**Recommended Resolutions:**
- **Primary**: 1080x1920px (9:16 aspect ratio)
- **Alternative sizes**: 720x1280px, 1440x2560px, 2160x3840px

**Design Guidelines:**
- Keep important elements in center 60% of screen
- Use high contrast for accessibility
- Consider the app's purpose (banknote detection for visually impaired)

### 2. Files Modified
- `lib/main.dart` - Updated to use SplashScreen as home
- `pubspec.yaml` - Added assets/images/ directory
- `lib/screens/splash_screen.dart` - New splash screen implementation

## Feedback System Implementation

### 1. Core Components Created

#### `lib/widgets/feedback_widget.dart`
- Animated bottom sheet that appears when banknote is detected
- Thumbs up/down buttons for quick feedback
- Dropdown for correction when user selects "NO"
- Auto-dismisses after 10 seconds
- Dismisses when different banknote detected

#### `lib/utils/feedback_database.dart`
- SQLite database helper for storing feedback
- Tracks detection accuracy
- Provides statistics and analytics

#### `lib/screens/camera_screen_with_feedback.dart`
- Example implementation showing how to integrate feedback widget
- Handles feedback logic and database storage

### 2. Integration Steps

#### Step 1: Replace your camera screen
```dart
// In your existing camera screen, add these imports:
import 'package:ini_berapa/widgets/feedback_widget.dart';
import 'package:ini_berapa/utils/feedback_database.dart';

// Add these variables to your State class:
bool _showFeedback = false;
String? _currentDetectedValue;
String? _lastDetectedValue;
```

#### Step 2: Add feedback trigger
```dart
// When your ML model detects a banknote, call this:
void _onBanknoteDetected(String detectedValue) {
  // Only show feedback if it's a different banknote
  if (_lastDetectedValue != detectedValue) {
    setState(() {
      _currentDetectedValue = detectedValue;
      _lastDetectedValue = detectedValue;
      _showFeedback = true;
    });
  }
}
```

#### Step 3: Add feedback handlers
```dart
void _handleFeedback(bool isCorrect, String? actualValue) async {
  // Save to database
  await FeedbackDatabase.insertFeedback(
    detectedValue: _currentDetectedValue!,
    isCorrect: isCorrect,
    actualValue: actualValue,
    imagePath: 'path/to/current/image', // optional
    confidenceScore: 0.85, // from your ML model
  );
  
  print('Feedback saved: ${isCorrect ? "Correct" : "Incorrect"}');
  if (!isCorrect && actualValue != null) {
    print('Actual value: $actualValue');
  }
}

void _dismissFeedback() {
  setState(() {
    _showFeedback = false;
    _currentDetectedValue = null;
  });
}
```

#### Step 4: Add feedback widget to your UI
```dart
// In your build method, add this to your Stack:
if (_showFeedback && _currentDetectedValue != null)
  Positioned(
    bottom: 0,
    left: 0,
    right: 0,
    child: FeedbackWidget(
      detectedValue: _currentDetectedValue!,
      onFeedback: _handleFeedback,
      onDismiss: _dismissFeedback,
    ),
  ),
```

### 3. Feedback Behavior

The feedback widget will:
- ✅ Appear at bottom when banknote is detected
- ✅ Show detected value (e.g., "Rp 50,000")
- ✅ Provide YES/NO buttons
- ✅ Show dropdown for correction if NO is selected
- ✅ Auto-dismiss after 10 seconds
- ✅ Dismiss when different banknote is detected
- ✅ Store feedback in SQLite database

### 4. Database Schema

```sql
CREATE TABLE feedback(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  timestamp TEXT NOT NULL,
  detected_value TEXT NOT NULL,
  is_correct INTEGER NOT NULL,
  actual_value TEXT,
  image_path TEXT,
  confidence_score REAL
)
```

### 5. Analytics Available

```dart
// Get feedback statistics
final stats = await FeedbackDatabase.getFeedbackStats();
print('Accuracy: ${stats['accuracy_percentage']}%');
print('Total feedback: ${stats['total_feedback']}');
print('Common errors: ${stats['common_errors']}');
```

## Testing

1. **Splash Screen**: Run the app to see the new splash screen
2. **Feedback Widget**: Use the test button in `CameraScreenWithFeedback` to simulate detection
3. **Database**: Check feedback storage by calling `FeedbackDatabase.getAllFeedback()`

## Next Steps

1. Replace your current camera screen with the feedback-enabled version
2. Integrate the feedback trigger with your actual ML detection logic
3. Add analytics dashboard to view feedback statistics
4. Consider adding user settings to enable/disable feedback collection

## Dependencies Used

All required dependencies are already in your `pubspec.yaml`:
- `sqflite` - Database storage
- `path_provider` - File paths
- `intl` - Date formatting
