# SkillSwap - Peer-to-Peer Skill Exchange App
Zynvex Internship, Batch 4 - Modules 1 & 2

## Module 1 - User Authentication & Profile Setup
- Email/password sign up, login, logout, password reset (Firebase Auth) with validation and friendly errors
- Auth gate: logged out -> login; logged in without profile -> setup; otherwise -> home
- Profile: name, bio, profile photo (Firebase Storage), skills offered / skills wanted
- Edit profile, bottom-navigation shell

## Module 2 - Skill Listing & Matching
- Create / delete skill listings ("I can teach" or "I want to learn") with category, level, description
- Browse screen with live search plus type and category filters
- Matching algorithm (`lib/utils/matcher.dart`): 10 pts per skill they can teach you, 10 per skill you can
  teach them, +15 bonus for mutual exchanges; results sorted best-first and shown on the Matches tab
- Unit tests for the matcher (`flutter test`)

## Setup
1. Create a Firebase project; enable **Authentication -> Email/Password**, **Cloud Firestore**, **Storage**.
2. `flutter pub get`
3. `dart pub global activate flutterfire_cli && flutterfire configure`  (generates `lib/firebase_options.dart`)
4. Paste `firestore.rules` and `storage.rules` into the Firebase console (or `firebase deploy --only firestore:rules,storage`).
5. `flutter run`
6. Android: set `minSdkVersion 23` in `android/app/build.gradle` (needed by Firebase).
   iOS: add `NSPhotoLibraryUsageDescription` to `ios/Runner/Info.plist` (image picker).

If Firestore asks for an index on the listings query, open the link in the console error and create it.

## Structure
```
lib/
  main.dart                  app + AuthGate
  models/                    UserProfile, SkillListing
  services/                  Auth, User(+Storage), Listing
  providers/providers.dart   Riverpod providers (auth, profile, listings, filters, matches)
  utils/matcher.dart         matching algorithm
  screens/{auth,profile,home,skills,matches}
  widgets/                   UserAvatar, SkillChipInput
```
