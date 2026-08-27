# Google Sign-In Android (Api 10 / DEVELOPER_ERROR) Fix

Error `PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10:, null, null)` means **DEVELOPER_ERROR**: the app's package name or SHA-1 does not match any **Android** OAuth client in Google Cloud.

**You must have an OAuth client of type "Android"** (not just Web). One Web client alone will always give Api 10 on Android.

---

## Do this first: Create the Android OAuth client

1. Open: **[Google Cloud Console → Credentials](https://console.cloud.google.com/apis/credentials)**  
   (Use the same Google Cloud project as your Web client.)

2. Click **"+ CREATE CREDENTIALS"** → **"OAuth client ID"**.

3. If asked, choose **"Application type"** = **Android** (not Web).

4. Fill in **exactly**:
   - **Name:** e.g. `b_smart Android`
   - **Package name:** `com.ruvees.bsmart`
   - **SHA-1 certificate fingerprint:**  
     `5A:83:D0:59:42:30:EB:14:79:8E:76:43:C7:99:D0:28:C6:66:35:7C`

5. Click **Create**.  
   You’ll get an **Android** Client ID (it can be different from your Web client ID).

6. **(Optional)** Add SHA-256 to the same Android client (edit the client, add fingerprint):  
   `04:22:E6:53:D6:D2:CD:EF:3E:DB:78:CC:0D:71:7C:6D:86:B6:B8:B9:A1:6C:4C:B0:E0:4D:3E:05:0A:64:AE:98`

7. Wait **5–10 minutes** for Google to propagate, then run the app again.

---

## Local signing fingerprints

### Release keystore used by this repo

- **Package name:** `com.ruvees.bsmart`
- **SHA-1 (release keystore):** `5A:83:D0:59:42:30:EB:14:79:8E:76:43:C7:99:D0:28:C6:66:35:7C`
- **SHA-256 (release keystore):** `04:22:E6:53:D6:D2:CD:EF:3E:DB:78:CC:0D:71:7C:6D:86:B6:B8:B9:A1:6C:4C:B0:E0:4D:3E:05:0A:64:AE:98`

### Debug keystore

- **SHA-1:** `AE:B3:4B:02:3E:0F:74:8B:17:5E:8F:58:FC:86:8E:10:08:57:71:3F`
- **SHA-256:** `F3:D5:9A:83:CF:63:5A:EC:A8:ED:F6:CD:78:91:4D:26:F3:FD:EF:B0:FF:65:59:57:88:09:A6:A1:DA:8D:0E:0A`

## You need both clients in the same project

| Client type | Purpose |
|------------|--------|
| **Android** | So the Android app is recognized (package name + SHA-1). **Required to fix Api 10.** |
| **Web** | Used as `serverClientId` in the app and in Supabase Dashboard (with client secret). |

Keep your existing **Web** client for Supabase. Add the **Android** client as above; you don’t need to change the Web client ID in the app.

## Safe for phase 1

Do **not** delete the old Android OAuth client if the phase 1 app still depends on it.

Add the new release SHA-1 as an additional Android OAuth client in the same Google Cloud project, then keep both Android clients registered:

- Phase 1 client: leave it as-is
- Phase 2 release client: add `5A:83:D0:59:42:30:EB:14:79:8E:76:43:C7:99:D0:28:C6:66:35:7C`

## Verify SHA-1 on your machine

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

The SHA-1 in the output must match the one in the Android OAuth client in Google Cloud.

## After adding the Android client

- Wait 5–10 minutes.
- Rebuild: `flutter clean && flutter pub get && flutter run`.
