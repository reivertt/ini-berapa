# Splash Screen Demo

## 🎨 Visual Design

Your new splash screen perfectly recreates the CSS animation with:

### 📱 **Icon Container (256x256px)**
- **Gradient**: Radial gradient from bright purple `#7E08FC` to deep purple `#37145C`
- **Corner Radius**: 48px (iOS-style rounded corners)
- **Shadow**: Layered shadows for depth
- **Position**: Center of screen

### 🔤 **"Rp" Text**
- **Size**: 80px
- **Weight**: Extra bold (900)
- **Color**: White with subtle shadow
- **Position**: Center of icon container

### 📊 **Scanner Line Animation**
- **Color**: Vivid green `#00E676` 
- **Height**: 6px
- **Glow Effect**: Multiple shadow layers for neon effect
- **Animation**: Moves from 15% to 85% of container height
- **Duration**: 2.5 seconds, repeats infinitely
- **Easing**: Smooth ease-in-out curve

### 👋 **Welcome Text**
- **Text**: "Welcome to IniBerapa"
- **Size**: 24px
- **Weight**: Bold (700)
- **Color**: Deep purple `#37145C` (matches icon)
- **Position**: Below icon with 40px spacing

### 🎭 **Background**
- **Color**: Light gray `#F0F2F5` (matches your CSS)

## ⚡ **Animation Sequence**

1. **0.0s**: Splash screen fades in (800ms duration)
2. **0.5s**: Scanner line animation starts
3. **0.5s - 3.0s**: Scanner line continuously moves up and down
4. **3.0s**: Navigate to home screen

## 🔧 **Implementation Details**

### Files Created:
- `lib/screens/splash_screen_no_fonts.dart` - Main implementation (no custom fonts needed)
- `lib/screens/splash_screen.dart` - Version with Inter font support

### Current Setup:
- Using `SplashScreenNoFonts` in `main.dart` (easier to implement)
- No external font files required
- Uses system fonts with proper weights

### To Use Custom Inter Font:
1. Download Inter font files:
   - `Inter-Bold.ttf` (weight 700)
   - `Inter-Black.ttf` (weight 900)
2. Place in `fonts/` directory
3. Switch `main.dart` to use `SplashScreen` instead of `SplashScreenNoFonts`

## 🎯 **Exact CSS Match**

Your Flutter splash screen now matches your CSS animation:
- ✅ Same gradient colors
- ✅ Same dimensions (256x256px)
- ✅ Same corner radius (48px)
- ✅ Same scanner animation timing (2.5s)
- ✅ Same scanner line color and glow
- ✅ Same text positioning and styling
- ✅ Same background color
- ✅ Same shadow effects

## 🚀 **Ready to Test**

Run your app to see the animated splash screen in action! The scanner line will smoothly animate up and down while the "Welcome to IniBerapa" text appears below the icon.
