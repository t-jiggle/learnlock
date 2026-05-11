# Firebase Deployment Guide for LearnLock

Your Firestore configuration files have been created. Follow these steps to deploy them to your Firebase project.

## Prerequisites
- Install Node.js from https://nodejs.org/ (v16+ recommended)
- Install Firebase CLI: `npm install -g firebase-tools`

## Step 1: Initialize Firebase CLI
```bash
cd /home/tez/GITHUB/learnlock
firebase login
firebase init firestore
```

When prompted:
- Select project: `learnlock-886da`
- Use existing `firestore.rules` and `firestore.indexes.json` files

## Step 2: Deploy Rules and Indexes
```bash
firebase deploy --only firestore:rules,firestore:indexes
```

## Step 3: Create Initial Collections (via Firebase Console)

If you want to pre-populate empty collections, go to:
https://console.firebase.google.com/project/learnlock-886da/firestore

Or, create them programmatically by running the app and having a parent sign up (collections auto-create).

## Collections Created
- **`children`** — Child profiles with screen time and learning state
- **`progress`** — Learning progress tracking per child

## Security Rules
- Parents can only access their own children's data
- Children's data is protected via `parentUid` field
- All other access is denied

## Next Steps
After deployment:
1. Test Google Sign-In on the app
2. Create a child profile
3. Verify data appears in Firestore Console
