# SkillSwap - Peer-to-Peer Skill Exchange App
Zynvex Internship, Batch 4 - Modules 1-4

## Module 1 - User Authentication & Profile Setup
- Email/password sign up, login, logout, password reset (Firebase Auth) with validation and friendly errors
- Auth gate: logged out -> login; logged in without profile -> setup; otherwise -> home
- Profile: name, bio, profile photo (Firebase Storage), skills offered / skills wanted
- Edit profile, bottom-navigation shell

### UI design (Module 1 refresh)
- Login/Register: Taskly-style split card on wide screens (tagline + illustration | Login/Register toggle form), gradient header on phones
- SkillSwap branding: purple -> blue gradient, lavender surfaces (`lib/theme/app_theme.dart`)
- Connecti-style sidebar navigation on wide screens, bottom bar on phones
- Profile + setup screens use a gradient banner with overlapping avatar and coloured skill tags
- Profile photos now upload from bytes, so they work on web as well as mobile

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

## Module 4 - Availability, Scheduling & Notifications
- **Availability:** weekly recurring windows per day (Profile -> My availability), overlap-checked and saved to the user profile
- **Session scheduling:** from any chat, pick a date (calendar only allows days the partner is free), a start time inside their windows and a duration (30/60/90 min)
- Partner **confirms or declines**; proposer can cancel; either side can cancel a confirmed session or mark it completed
- Conflict check against your own confirmed sessions
- **Push notifications (FCM + Cloud Functions):** new request, request accepted/declined, new chat message, session proposed/confirmed/declined/cancelled/completed, and a reminder ~30 minutes before a confirmed session
- Device tokens are stored privately in `users/{uid}/tokens`; removed on logout; notification taps open the Swaps or Chats tab
- Requests and sessions now live on one **Swaps** tab (Received / Sent / Sessions) with a combined badge

Limitation: availability is treated as local time, so it assumes both partners are in the same time zone.

### Deploying notifications
1. Upgrade the Firebase project to the **Blaze** plan (Cloud Functions and Scheduler require it).
2. `cd functions && npm install && cd ..`
3. `firebase deploy --only firestore:rules,firestore:indexes,functions`
4. Android 13+: make sure `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>` is in `android/app/src/main/AndroidManifest.xml`.
5. iOS: upload your APNs key in Firebase console -> Project settings -> Cloud Messaging, and enable Push Notifications + Background Modes in Xcode.
Without the functions deployed, everything else still works; only the push alerts are missing.

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
  screens/{auth,profile,home,skills,matches,requests,chat,availability,sessions}
functions/                   Cloud Functions (push notifications + reminders)
  widgets/                   UserAvatar, SkillChipInput
```
