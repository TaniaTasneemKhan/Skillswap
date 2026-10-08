# SkillSwap - Peer-to-Peer Skill Exchange App
Zynvex Internship, Batch 4 - Modules 1, 2 & 3

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

## Module 3 - Exchange Requests & Chat
- **Send** a swap request from the Matches tab or any listing on Browse (what I teach / what I learn + optional message)
- **Accept / decline** incoming requests; **cancel** your own pending ones; status chips + badge for pending count
- Accepting creates the chat (`chats/{uidA_uidB}`) in the same atomic batch
- **Real-time one-to-one chat** over `chats/{id}/messages`, chat list with last-message preview
- Duplicate-request protection (button shows "Request sent" / "Open chat")
- Firestore rules updated: only participants can read; receiver accepts/rejects, sender cancels, only while pending

Collections: `requests`, `chats`, `chats/{id}/messages`. Remember to re-publish `firestore.rules`.

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
  screens/{auth,profile,home,skills,matches,requests,chat}
  widgets/                   UserAvatar, SkillChipInput
```

