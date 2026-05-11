# Google Sign-In Setup Guide for LearnLock

Follow these steps to enable Google Sign-In authentication for parent accounts.

## Step 1: Go to Firebase Console
1. Open https://console.firebase.google.com/project/learnlock-886da
2. Sign in with your Google account (the one managing the Firebase project)

## Step 2: Enable Google Sign-In Provider
1. In the left sidebar, click **Authentication**
2. Click the **Sign-in method** tab
3. You'll see a list of sign-in providers (Google, Facebook, GitHub, etc.)
4. Click on **Google**
5. Toggle the switch to **Enable** (turn it ON)
6. You'll see a form with:
   - **Project name** — Keep as is (auto-filled)
   - **Project support email** — Select your email from dropdown
7. Click **Save**

## Step 3: Verify Android App is Listed
1. Scroll down after saving — you should see an "Android" section showing:
   - **Package name:** `com.tezjmc.learnlock`
   - **SHA-1 fingerprint:** A hash code
2. This is auto-populated from your `google-services.json`

✅ If you see both fields, **Google Sign-In is configured for Android**.

## Step 4: Verify OAuth Consent Screen (Usually Auto-Configured)
1. Go to **APIs & Services** (in the top-left menu or click the menu icon)
2. Click **OAuth consent screen**
3. Make sure it shows your app name and support email
4. If it shows "External" user type, that's fine for testing
5. No changes needed — just verify it's there

## Step 5: Test the Configuration
Your app is now ready. When you install the APK and run it:

1. Tap **Sign in with Google**
2. A Google login popup appears
3. Select your test Google account
4. App asks for permission to access basic profile
5. You'll be signed in and can create child profiles

## Troubleshooting

**"Google sign-in failed" error:**
- Verify `google-services.json` is in `/android/app/`
- Check that the SHA-1 fingerprint in Firebase matches your signing key
- Ensure Google provider is enabled (toggle is ON)

**"This app isn't verified" warning:**
- Normal for apps in development
- Click "Advanced" → "Go to learnlock (unsafe)" to proceed
- This goes away once you publish to Play Store

## Next: Deploy Firestore
Once Google Sign-In is working, deploy your Firestore database:
```bash
cd /home/tez/GITHUB/learnlock
firebase login
firebase deploy --only firestore:rules,firestore:indexes
```

Then you can fully test parent sign-up → create child → view progress.
