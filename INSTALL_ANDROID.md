# Installing Beacon App on Android Device

## Method 1: USB Debugging (Recommended for Development)

### Prerequisites
1. **Enable Developer Options** on your Android device:
   - Go to **Settings** → **About Phone**
   - Find **Build Number** and tap it **7 times** until you see "You are now a developer!"

2. **Enable USB Debugging**:
   - Go to **Settings** → **Developer Options** (or **System** → **Developer Options**)
   - Enable **USB Debugging**
   - Optionally enable **Install via USB** (if available)

3. **Connect your device**:
   - Connect your Android device to your computer via USB cable
   - On your device, tap **Allow** when prompted "Allow USB debugging?"
   - Check "Always allow from this computer" if you want to skip this prompt in the future

### Install and Run

1. **Navigate to project directory**:
   ```bash
   cd beacon
   ```

2. **Check if device is detected**:
   ```bash
   flutter devices
   ```
   You should see your device listed (e.g., "SM-G991B" or similar device name)

3. **Run the app**:
   ```bash
   flutter run
   ```
   Or specify your device explicitly:
   ```bash
   flutter run -d <device-id>
   ```

   The app will be installed and launched automatically on your device.

---

## Method 2: Build APK and Install Manually

### Build the APK

1. **Navigate to project directory**:
   ```bash
   cd beacon
   ```

2. **Build the APK**:
   ```bash
   flutter build apk
   ```
   
   For a release build (smaller size, optimized):
   ```bash
   flutter build apk --release
   ```

3. **Find the APK**:
   The APK will be located at:
   ```
   beacon/build/app/outputs/flutter-apk/app-release.apk
   ```

### Install the APK

**Option A: Using ADB (if device is connected via USB)**
```bash
flutter install
```
Or manually:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

**Option B: Transfer and Install Manually**
1. Copy the APK file (`app-release.apk`) to your Android device (via USB, email, cloud storage, etc.)
2. On your Android device:
   - Open **Files** or **File Manager**
   - Navigate to where you saved the APK
   - Tap the APK file
   - If prompted, enable **Install from Unknown Sources** in Settings
   - Tap **Install**
   - Tap **Open** when installation completes

---

## Troubleshooting

### Device Not Detected
- Make sure USB debugging is enabled
- Try a different USB cable
- Try a different USB port
- On your device, revoke USB debugging authorizations and reconnect
- Run `flutter doctor` to check for issues

### Installation Fails
- Make sure you have enough storage space on your device
- Check if an older version of the app is installed (uninstall it first)
- For release builds, you may need to uninstall the debug version first

### Permission Issues
- The app requires location permissions for WiFi Direct features
- Grant permissions when prompted on first launch

---

## Quick Commands Reference

```bash
# Check connected devices
flutter devices

# Run on connected device
flutter run

# Build APK
flutter build apk --release

# Install APK via ADB
flutter install

# Check Flutter setup
flutter doctor
```


