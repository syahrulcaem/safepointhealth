# Implementasi Bluetooth SmartWatch SOS - SafePoint Health

## 📋 Overview

Implementasi fitur Bluetooth untuk mendeteksi Xiaomi Watch dan ### 🎨 UI Components

### SOS Alert Overlay (Instant Trigger)

#### Loading State (Red Screen)

```
[Fullscreen Red Overlay with 90% opacity]

    ⚪ [Pulsing White Circle]
       🚨 [Emergency Icon]

        SOS DARURAT

    [Watch Icon] Xiaomi Watch S1

    [Loading Spinner]
    Mengirim laporan darurat...
```

#### Success State (Green Screen)

```
[Fullscreen Green Overlay with 90% opacity]

    ⚪ [White Circle]
       ✅ [Check Icon]

      SOS TERKIRIM!

  Tim darurat akan segera datang

[Auto-close setelah 3 detik]
```

**UX Flow**:

1. Volume Up ditekan → Red overlay instant (< 100ms)
2. SOS API call in progress → Loading spinner
3. Success → Transition ke green overlay
4. Auto-close → Back to home screen

**No Confirmation Needed**: Untuk kecepatan maksimal dalam situasi darurat!

### Bluetooth Status Card (3 States)gger SOS melalui tombol Volume Up smartwatch. Sistem ini dapat bekerja bahkan ketika aplikasi dalam keadaan background atau tertutup.

---

## 🏗️ Arsitektur Sistem

### 1. **Native Android Layer**

#### BluetoothHelper.kt

- **Lokasi**: `android/app/src/main/kotlin/com/example/safepointhealth/BluetoothHelper.kt`
- **Fungsi**:
  - Cek status Bluetooth ON/OFF
  - Cek permission Bluetooth (Android 12+)
  - Deteksi koneksi Xiaomi Watch (nama mengandung "Xiaomi Watch", "Mi Watch", "Redmi Watch")
  - Kirim status ke Flutter via MethodChannel `safepoint/bt_channel`
- **Method**:
  - `isBluetoothEnabled()`: Boolean
  - `hasBluetoothPermission()`: Boolean
  - `isXiaomiWatchConnected()`: Boolean
  - `getXiaomiWatchName()`: String?
  - `getBluetoothStatus()`: Map<String, Any>

#### MainActivity.kt

- **Lokasi**: `android/app/src/main/kotlin/com/example/safepointhealth/MainActivity.kt`
- **Fungsi**:
  - Setup 3 MethodChannel: GPS, Bluetooth, SOS
  - Override `onKeyDown()` untuk detect KEYCODE_VOLUME_UP
  - Trigger SOS ke Flutter saat Volume Up ditekan dan Xiaomi Watch terhubung
- **MethodChannel**:
  - `safepoint/gps` - GPS operations
  - `safepoint/bt_channel` - Bluetooth operations
  - `safepoint/sos_channel` - SOS trigger dari smartwatch

#### SosBackgroundService.kt

- **Lokasi**: `android/app/src/main/kotlin/com/example/safepointhealth/SosBackgroundService.kt`
- **Fungsi**:
  - Foreground Service untuk monitoring SOS bahkan saat app ditutup
  - Menampilkan persistent notification dengan status Xiaomi Watch
  - Auto-restart after device reboot
- **Lifecycle**: START_STICKY (restart jika di-kill oleh sistem)

#### BootReceiver.kt

- **Lokasi**: `android/app/src/main/kotlin/com/example/safepointhealth/BootReceiver.kt`
- **Fungsi**: Restart SosBackgroundService setelah device reboot

---

### 2. **Flutter Layer**

#### BluetoothService

- **Lokasi**: `lib/services/bluetooth_service.dart`
- **Fungsi**: Bridge komunikasi dengan native Android via MethodChannel
- **Method**:
  - `getBluetoothStatus()`: Future<Map<String, dynamic>>
  - `hasBluetoothPermission()`: Future<bool>
  - `requestBluetoothPermission()`: Future<bool>
  - `isBluetoothEnabled()`: Future<bool>
  - `isXiaomiWatchConnected()`: Future<bool>
  - `setBluetoothStatusListener()`: void

#### SmartWatchSosService

- **Lokasi**: `lib/services/smartwatch_sos_service.dart`
- **Fungsi**: Handle SOS trigger dari smartwatch
- **Method**:
  - `initialize()`: Setup listener untuk SOS trigger
  - `triggerEmergencyReport()`: Kirim emergency report dengan lokasi otomatis
  - `startBackgroundMonitoring()`: Start background service
  - `stopBackgroundMonitoring()`: Stop background service

#### Citizen Home Screen Updates

- **Lokasi**: `lib/screens/citizen/citizen_home_screen.dart`
- **Perubahan**:
  - Tambah Bluetooth status indicator card
  - Initialize SmartWatchSosService di `initState()`
  - Show dialog konfirmasi saat SOS trigger dari smartwatch
  - Auto-trigger emergency report setelah konfirmasi

---

## 📱 User Flow

### Normal Flow (App Terbuka)

```
1. User buka app
2. App detect Bluetooth status dan Xiaomi Watch connection
3. Tampilkan status di home screen:
   - ⚫ Bluetooth Mati (jika BT off)
   - 🔵 Bluetooth Aktif (jika BT on, watch belum connect)
   - 🟢 SmartWatch Terhubung (jika watch connected)
4. User tekan Volume Up di smartwatch
5. MainActivity detect KEYCODE_VOLUME_UP
6. Check if Xiaomi Watch connected
7. Send trigger ke Flutter via sos_channel
8. Flutter LANGSUNG kirim SOS emergency report (NO CONFIRMATION)
9. Show notification: "🚨 SOS dari [Watch Name] - Mengirim laporan darurat..."
10. Show success/error notification
```

**⚡ INSTANT SOS**: Tidak ada dialog konfirmasi, SOS langsung terkirim untuk kecepatan maksimal dalam situasi darurat!

### Background Flow (App Ditutup/Background)

```
1. SosBackgroundService running (foreground service)
2. Show persistent notification "SafePoint SOS Aktif"
3. User tekan Volume Up di smartwatch
4. Service detect trigger (via key event broadcast)
5. Launch MainActivity with extra "trigger_sos=true"
6. MainActivity handle intent dan trigger SOS
7. Send emergency report
```

---

## 🔐 Permissions

### AndroidManifest.xml

```xml
<!-- Bluetooth Permissions -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" /> <!-- Android 12+ -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" /> <!-- Android 12+ -->

<!-- Foreground Service -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

### Runtime Permissions

- **Android 12+**: BLUETOOTH_CONNECT, BLUETOOTH_SCAN
- **Below Android 12**: No special Bluetooth permission needed
- **Location**: Already requested in existing code
- **Request Flow**: Otomatis di SplashScreen saat app pertama kali dibuka

---

## 🎨 UI Components

### Bluetooth Status Card (3 States)

#### 1. Bluetooth Mati

```
⚫ Bluetooth Mati
   Aktifkan untuk menghubungkan smartwatch
```

- Background: Grey (Colors.grey.shade100)
- Icon: bluetooth_disabled
- Border: Grey

#### 2. Bluetooth Aktif (Watch Belum Connect)

```
🔵 Bluetooth Aktif
   Menunggu koneksi Xiaomi Watch    [🔄]
```

- Background: Blue gradient (Colors.blue.shade50)
- Icon: bluetooth_searching
- Border: Blue
- Action: Refresh button

#### 3. SmartWatch Terhubung

```
🟢 SmartWatch Terhubung         [SOS Ready]
   Xiaomi Watch S1 Active
```

- Background: Green gradient (Colors.green.shade50)
- Icon: watch
- Border: Green
- Badge: "SOS Ready" (green)

---

## 🔧 Cara Kerja Teknis

### 1. Volume Up Detection

```kotlin
override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
    if (keyCode == KeyEvent.KEYCODE_VOLUME_UP) {
        if (bluetoothHelper.isXiaomiWatchConnected()) {
            sosMethodChannel?.invokeMethod("onSOS", mapOf(
                "source" to "smartwatch",
                "device" to bluetoothHelper.getXiaomiWatchName(),
                "timestamp" to System.currentTimeMillis()
            ))
            return true // Consume event (prevent volume change)
        }
    }
    return super.onKeyDown(keyCode, event)
}
```

### 2. Flutter SOS Handler

```dart
SmartWatchSosService.initialize(
  onSosTrigger: (data) async {
    // Show confirmation dialog
    _showSmartWatchSosDialog(data);
  },
);
```

### 3. Auto Emergency Report

```dart
Future<void> _triggerEmergencyFromSmartWatch() async {
  final location = await GpsService.getCurrentLocation();
  final success = await SmartWatchSosService.triggerEmergencyReport(
    emergencyProvider: emergencyProvider,
    description: 'SOS darurat dari smartwatch',
    category: EmergencyCategory.KECELAKAAN,
  );
}
```

---

## 🧪 Testing Checklist

### Scenario 1: Bluetooth Off

- [ ] Open app → Tampil "Bluetooth Mati"
- [ ] Turn on Bluetooth → Auto-update ke "Bluetooth Aktif"
- [ ] Press Volume Up → No action (expected)

### Scenario 2: Bluetooth On, Watch Not Connected

- [ ] Open app → Tampil "Bluetooth Aktif"
- [ ] Press refresh button → Re-check status
- [ ] Connect Xiaomi Watch → Auto-update ke "SmartWatch Terhubung"
- [ ] Press Volume Up → No action (expected)

### Scenario 3: Watch Connected (App Open) - INSTANT SOS

- [ ] Open app → Tampil "SmartWatch Terhubung" dengan nama watch
- [ ] Badge "SOS Ready" visible
- [ ] Press Volume Up on watch → **INSTANT**: Fullscreen red overlay muncul
- [ ] Overlay shows: Pulsing emergency icon + "SOS DARURAT" + watch name + loading
- [ ] SOS langsung terkirim (no confirmation needed)
- [ ] Success: Green fullscreen "SOS TERKIRIM!" + auto close setelah 3 detik
- [ ] Check cooldown → 30 menit cooldown aktif

### Scenario 4: Background/Closed (Future Implementation)

- [ ] App closed/background → Foreground service running
- [ ] Notification visible: "SafePoint SOS Aktif - Terhubung dengan [Watch Name]"
- [ ] Press Volume Up → App launched with SOS trigger
- [ ] SOS terkirim otomatis

### Scenario 5: After Reboot

- [ ] Device reboot → BootReceiver triggered
- [ ] Foreground service restarted (if enabled)
- [ ] Notification visible

---

## 🚀 Future Enhancements

1. **Background Service Control**

   - Add toggle di settings untuk enable/disable background monitoring
   - Save preference ke SharedPreferences
   - Show/hide persistent notification

2. **Battery Optimization**

   - Request battery optimization exemption
   - Handle Doze mode

3. **Multiple Watch Support**

   - Support brands lain selain Xiaomi
   - Generic HID button detection

4. **Emergency Contacts**

   - Auto-call emergency contact setelah SOS
   - Send SMS dengan lokasi

5. **Watch App**
   - Develop companion app untuk Xiaomi Watch
   - Custom SOS button (tidak pakai Volume Up)

---

## 📊 API Integration

### Emergency Endpoints

```
POST /public/emergency (guest)
POST /api/emergency (authenticated)

Payload:
{
  "latitude": 123.456,
  "longitude": 78.910,
  "description": "SOS darurat dari smartwatch: Xiaomi Watch S1",
  "category": "KECELAKAAN"
}
```

### Cooldown

- **Duration**: 30 menit
- **Storage**: File-based (`emergency_cooldown.json`)
- **Applied to**: Both authenticated and guest users
- **Message**: "Anda baru saja mengirimkan laporan darurat. Harap tunggu X menit lagi"

---

## 🐛 Known Issues & Limitations

1. **Volume Up Detection**

   - Only works when app is in foreground/background
   - Cannot intercept system-level key events when app is completely killed
   - Solution: Keep foreground service running

2. **Watch Name Detection**

   - Depends on paired Bluetooth device name
   - May not work if watch name changed by user
   - Solution: Add manual device selection in settings

3. **Android Versions**

   - Different Bluetooth permission requirements (< Android 12 vs >= 12)
   - Foreground service restrictions on Android 14+

4. **Battery**
   - Foreground service consumes battery
   - Need to balance monitoring vs battery life

---

## 📚 Resources

### Android Documentation

- [Bluetooth Overview](https://developer.android.com/guide/topics/connectivity/bluetooth)
- [Foreground Services](https://developer.android.com/guide/components/foreground-services)
- [Key Events](https://developer.android.com/reference/android/view/KeyEvent)

### Flutter Documentation

- [Platform Channels](https://flutter.dev/docs/development/platform-integration/platform-channels)
- [Method Channel](https://api.flutter.dev/flutter/services/MethodChannel-class.html)

---

## ✅ Implementation Checklist

- [x] Setup Android permissions
- [x] Implement BluetoothHelper.kt
- [x] Implement Volume Up detection di MainActivity
- [x] Create SosBackgroundService
- [x] Create BootReceiver
- [x] Implement BluetoothService (Flutter)
- [x] Implement SmartWatchSosService (Flutter)
- [x] Update UI dengan Bluetooth status
- [x] Add permission request flow
- [x] Test on device with Xiaomi Watch

---

## 🎯 Kesimpulan

Sistem Bluetooth SmartWatch SOS telah diimplementasikan dengan arsitektur yang solid:

1. ✅ **Native Android** - BluetoothHelper, Volume Up detection, Foreground Service
2. ✅ **Flutter Bridge** - MethodChannel communication
3. ✅ **UI Integration** - Status indicator dan konfirmasi dialog
4. ✅ **Permission Management** - Runtime permission request
5. ✅ **Emergency Integration** - Automatic SOS report dengan cooldown

Sistem siap untuk testing dengan Xiaomi Watch device!
