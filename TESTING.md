# SkillSwap - Final Test Checklist

Run with two accounts (A and B), e.g. two browser profiles or an emulator + Chrome.
Automated tests: `flutter test` (matcher, availability, sessions, chat id, reputation, widgets).

| # | Module | Steps | Expected |
|---|--------|-------|----------|
| 1 | Auth | Register A with a weak password (<6 chars) | Validation message, no account created |
| 2 | Auth | Register A with a valid email | Goes to profile setup |
| 3 | Auth | Log in with a wrong password | "Incorrect email or password." |
| 4 | Auth | Forgot password with a valid email | "Password reset email sent." |
| 5 | Profile | Finish setup with no skills | Blocked with a message |
| 6 | Profile | Add name, bio, photo, 2 offered + 2 wanted skills | Lands on Browse; profile shows the data |
| 7 | Listings | Post a listing as A | Appears on Browse immediately |
| 8 | Listings | Search a word from the title; use the filters | List narrows correctly |
| 9 | Matches | B offers what A wants and wants what A offers | B appears on A's Matches with "Mutual" |
| 10 | Requests | A taps "Request swap" on B | B sees it under Swaps -> Received (badge shows 1) |
| 11 | Requests | B accepts | A sees "Accepted"; both can open the chat |
| 12 | Requests | B declines a different request | A sees "Declined"; A can request again |
| 13 | Chat | Send messages both ways | Appear instantly on both sides |
| 14 | Availability | B adds Mon 09:00-11:00 and saves | Saved; shows "(1 slots)" on profile |
| 15 | Sessions | A opens chat -> calendar icon | Only Mondays are selectable; start times fit inside 09:00-11:00 |
| 16 | Sessions | A proposes; B confirms | Status Confirmed on both sides |
| 17 | Sessions | Propose a session overlapping a confirmed one | Blocked with a clear message |
| 18 | Sessions | After the start time, press "Mark completed" | Rating sheet opens |
| 19 | Reviews | A submits 5 stars + comment | B's profile shows 5.0 (1) and the review |
| 20 | Reviews | A tries to review the same session again | Button shows "Reviewed" |
| 21 | Reviews | Try to review a session that is not completed | Rejected by security rules |
| 22 | Profile | Tap a name on Matches/Browse/Chat header | Public profile with rating, skills, reviews |
| 23 | Push | (Functions deployed) A sends B a message with B's app in background | Notification arrives |
| 24 | Layout | Resize the browser narrow/wide | Sidebar <-> bottom bar; content stays readable |

## Known limitations
- Availability assumes both partners are in the same time zone.
- Push notifications need the Cloud Functions (Blaze plan); everything else works without them.
- Profile photos on web need CORS configured on the Firebase Storage bucket.
