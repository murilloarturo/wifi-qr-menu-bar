# WiFi QR

Shows the password of the Wi-Fi network your Mac is on as a QR code, right from the menu bar. Guests scan it with their phone camera to join.

## Use

Click the QR icon in the menu bar, then **Show Password**. The first time, macOS asks for two things:

1. **Location access.** macOS only tells apps the name of the Wi-Fi network if they have location access. If Location Services is off, or WiFi QR was turned down, **Open Location Settings** takes you to the right page and shows which switch to turn on. WiFi QR carries on by itself once it's on.
2. **An administrator's password.** Wi-Fi passwords are kept in the System keychain. Choose **Always Allow** to skip this step next time. macOS asks again after you rebuild the app.

Closing the panel hides the password again.

## Build

You need macOS 14 or later, Xcode 26 or later, and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
brew install xcodegen
git clone https://github.com/murilloarturo/wifi-qr-menu-bar.git
cd wifi-qr-menu-bar
Scripts/run.sh Release
```

To keep it, copy `.build/DerivedData/Build/Products/Release/WiFi QR.app` to your Applications folder. To work on it in Xcode, run `xcodegen generate` and open `WiFiQR.xcodeproj`.
