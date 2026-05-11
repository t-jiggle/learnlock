# Family Link Integration Architecture

## Overview

LearnLock integrates with **Google Family Link** to enable seamless parent-child device management. Instead of requiring manual device pairing or parent sign-in on child devices, LearnLock automatically detects the parent-child relationship already established in Family Link.

**Key Benefits:**
- ✅ Children sign in with their own Google accounts (age-appropriate)
- ✅ Parents use one account to manage all supervised children
- ✅ No manual device linking or QR codes needed
- ✅ Automatic profile provisioning for children
- ✅ Leverages existing Family Link infrastructure

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     Google Family Link                       │
│  (Central parent-child relationship repository)              │
└─────────────────────────────────────────────────────────────┘
                    ↓ (API calls)
        ┌───────────────────────────┐
        │  Family Link API           │
        │  (googleapis package)      │
        └───────────────────────────┘
           ↓                      ↓
    ┌──────────────┐      ┌──────────────┐
    │ Parent Device│      │ Child Device │
    └──────────────┘      └──────────────┘
           │                     │
      Parent Signs In       Child Signs In
           ↓                     ↓
    (userRole = parent)   (userRole = child)
           ↓                     ↓
    Parent Dashboard       Child Home Screen
      (configure            (auto-load profile,
       children's            start learning)
       settings)             
           ↓
      Firestore
    (stores child profiles
     with googleAccountId)
```

---

## User Role Detection Flow

### Step 1: User Signs In with Google
- Both parents and children use "Continue with Google" button
- OAuth flow completes, user gets access token

### Step 2: App Queries Family Link API
After auth succeeds, `FamilyLinkService.getUserRole()` is called:

```dart
final role = await familyLinkService.getUserRole(firebaseUser);
// Returns: UserRole.parent | UserRole.child | UserRole.independent
```

**How Role Detection Works:**

1. **Parent Detection**: Call `families.get('families/myFamily')` with parent's access token
   - Success → User is a parent (supervises family)
   - Failure → Not a parent

2. **Child Detection**: Check if user's account is in a family group but not parent
   - In family + not parent → User is a child
   - No family → User is independent

### Step 3: Role-Based Routing
Router automatically redirects based on detected role:

```dart
// In app_router.dart redirect logic
if (role == UserRole.parent) {
  router.go('/parent');           // Parent Dashboard
} else if (role == UserRole.child) {
  router.go('/child');            // Child Home
} else {
  router.go('/parent');           // Independent (can add children manually)
}
```

---

## Data Flow: Parent Setup

```
Parent Device
    ↓
 Google Sign-In
    ↓
 Get Access Token
    ↓
 Query Family Link API: families.members.list()
    ↓
 Get list of supervised children:
 [{email: child@gmail.com, name: Alice, age: 7, ...}, ...]
    ↓
 Display in Parent Dashboard
    ↓
 Parent configures learning settings:
 - Enabled subjects (Spelling, Maths, etc.)
 - Minutes required to earn screen time
 - Screen time reward amount
    ↓
 Settings stored in Firestore as ChildProfile:
 {
   id: uuid(),
   name: "Alice",
   ageYears: 7,
   parentUid: parent_firebase_uid,
   googleAccountId: "child@gmail.com",
   familyLinkId: "family_link_id_from_api",
   linkedType: "familyLink",
   enabledSubjects: ["spelling", "maths"],
   learningMinutesRequired: 5,
   earnedScreenMinutes: 30,
   createdAt: now(),
   ... (other settings)
 }
```

---

## Data Flow: Child Setup

```
Child Device
    ↓
 Google Sign-In (using child's account)
    ↓
 Get Access Token
    ↓
 App detects role: userRole = child
    ↓
 AUTO-PROVISION: Look up child profile in Firestore
 by googleAccountId (child's email)
    ↓
 If profile not found:
   - Query Family Link API to confirm parent-child relationship
   - Create new profile with parent's default settings
   - Auto-save to Firestore
    ↓
 Profile loaded into app state
    ↓
 Child sees learning interface with their configured subjects
```

---

## Model Changes

### ChildProfile (Extended)

**New Fields:**
```dart
String? googleAccountId;      // Child's Google account email
String? familyLinkId;         // Family Link supervised account ID  
LinkedAccountType linkedType; // enum: manual | familyLink
```

**Purpose:**
- `googleAccountId`: Link child profile to their Google sign-in account
- `familyLinkId`: Store Family Link API ID for future syncing
- `linkedType`: Track whether profile was manually created or auto-provisioned

### SupervisedAccount (New Model)

Represents a child from Family Link API:
```dart
class SupervisedAccount {
  String email;           // Google account email
  String familyLinkId;    // Family Link ID
  String displayName;     // Display name
  String? photoUrl;       // Profile picture
  int ageYears;           // Age
  DateTime createdAt;     // When account was created
}
```

---

## Firestore Schema

### children Collection

```firestore
/children/{childId}
  ├─ id: string (UUID)
  ├─ name: string
  ├─ ageYears: int
  ├─ parentUid: string (FK to Firebase Auth)
  ├─ googleAccountId: string (NEW - child's Google email)
  ├─ familyLinkId: string (NEW - Family Link ID)
  ├─ linkedType: string (NEW - "manual" | "familyLink")
  ├─ enabledSubjects: array<string>
  ├─ learningMinutesRequired: int
  ├─ earnedScreenMinutes: int
  ├─ currentEarnedMinutes: int
  ├─ screenTimeExpiresAt: timestamp (nullable)
  ├─ isActive: boolean
  └─ createdAt: timestamp
```

### progress Collection

```firestore
/progress/{childId}
  ├─ childId: string (FK to children)
  ├─ currentStreak: int
  ├─ totalMinutesLearned: int
  ├─ sessionsCompleted: int
  ├─ lastLearningDate: date
  └─ subjectProgress: map<subject, data>
```

---

## Security Model

### Firestore Rules

**Children Collection:**
```firestore
match /children/{childId} {
  // Parent can read/write their own children
  allow read: if request.auth.uid == resource.data.parentUid;
  allow write: if request.auth.uid == resource.data.parentUid;
  
  // Child can read their own profile
  allow read: if request.auth.uid == resource.data.googleAccountId;
  
  // Only parent can create
  allow create: if request.auth.uid == request.resource.data.parentUid;
}
```

**Progress Collection:**
```firestore
match /progress/{childId} {
  // Parent can read child's progress
  allow read: if request.auth.uid == 
    get(/databases/(default)/documents/children/$(childId)).data.parentUid;
  
  // Child can read/write their own progress
  allow read, write: if request.auth.uid == 
    get(/databases/(default)/documents/children/$(childId)).data.googleAccountId;
}
```

---

## Service Architecture

### FamilyLinkService

**Responsibilities:**
- Wrap Google Family Link API (via `googleapis` package)
- Detect user role (parent/child/independent)
- Fetch list of supervised children

**Public Methods:**
```dart
// Determine if authenticated user is parent, child, or independent
Future<UserRole> getUserRole(User? user)

// Get list of supervised children (parent only)
Future<List<SupervisedAccount>> fetchSupervisedAccounts()

// Get current user's Google account email
String? getCurrentUserEmail()
```

### Providers (Riverpod)

**`userRoleProvider`** - FutureProvider
- Queries Family Link API to determine role
- Returns `UserRole` enum

**`familyLinkSupervisedProvider`** - FutureProvider
- Fetches parent's supervised children from Family Link
- Returns `List<SupervisedAccount>`

**`childProfileByGoogleIdProvider`** - FutureProvider.family
- Looks up child profile by Google account ID
- Used during child login to auto-load profile

---

## Error Handling

### Family Link API Not Available
- If Family Link API fails: Default to `UserRole.independent`
- Parent can still manually add children
- Child won't be auto-detected, but can use manual login

### Child Profile Not Found
- Child signs in but profile doesn't exist
- App auto-creates profile from parent's Family Link settings
- If parent settings don't exist, use LearnLock defaults

### Missing Supervision Relationship
- Child's account is not supervised by a Family Link parent
- Treated as independent user
- Cannot access learning interface (no profile)

---

## Backward Compatibility

### Manual Child Creation Still Works
- Parents can still manually create child profiles without Family Link
- Profiles created without `googleAccountId` use `linkedType: manual`
- Both manual and Family Link children appear in parent dashboard

### Mixed Environment
- Parent can have both Family Link children and manually-created children
- Both types sync to same Firestore collection
- Both types function identically in learning interface

---

## Implementation Checklist

- [x] Add `googleapis` package to pubspec.yaml
- [x] Create `FamilyLinkService` to query Family Link API
- [x] Create `UserRole` model and enums
- [x] Create `SupervisedAccount` model
- [x] Update `ChildProfile` with `googleAccountId`, `familyLinkId`, `linkedType`
- [x] Create `userRoleProvider` for role detection
- [x] Create `familyLinkSupervisedProvider` for fetching supervised children
- [x] Update router to branch based on `userRole`
- [x] Update Firestore rules for child read access
- [x] Add methods to `FirebaseService` for child lookup and linking
- [x] Update parent provider to handle Family Link children
- [x] Add auto-provisioning logic for child profiles
- [ ] Test parent setup flow
- [ ] Test child setup flow
- [ ] Test manual child creation still works
- [ ] Add error recovery tests

---

## Testing

See [SETUP_PARENT_DEVICE.md](SETUP_PARENT_DEVICE.md) and [SETUP_CHILD_DEVICE.md](SETUP_CHILD_DEVICE.md) for end-to-end testing instructions.
