You are working on my existing Flutter application called "bSmart".

I need you to integrate Google AdMob into the EXISTING Flutter project. Do not rebuild, restructure, or rewrite unrelated parts of the application.

IMPORTANT:
- First inspect the existing project structure and understand how the app currently works.
- Identify the current Flutter version, Android configuration, package/application ID, existing dependencies, navigation structure, post creation/publishing flow, and feed/content UI.
- Do not make destructive changes.
- Do not remove or replace existing functionality.
- Preserve the current UI and architecture as much as possible.
- Before modifying anything, inspect the relevant files and explain briefly what you found.
- Then implement the changes carefully.

==================================================
PROJECT
==================================================

App name:
bSmart

Platform currently being configured:
Android

The app is built with Flutter.

==================================================
ADMOB CONFIGURATION
==================================================

I have already created the following AdMob configuration for bSmart Android.

ANDROID ADMOB APP ID:
ca-app-pub-6848080783292385~6565575168

ANDROID PRODUCTION AD UNIT IDS:

Banner:
ca-app-pub-6848080783292385/7997699035

Interstitial:
ca-app-pub-6848080783292385/5739578658

Native Advanced:
ca-app-pub-6848080783292385/7115862201

DO NOT use these production ad unit IDs during development/testing.

During development, use Google's official AdMob TEST ad unit IDs.

For Android, use:

Banner test ID:
ca-app-pub-3940256099942544/6300978111

Interstitial test ID:
ca-app-pub-3940256099942544/1033173712

Native Advanced test ID:
ca-app-pub-3940256099942544/2247696110

Do not use fake IDs.

The production IDs should be stored in one centralized configuration so that they can be switched on later without searching through the entire codebase.

==================================================
REQUIRED AD FORMATS
==================================================

The product/admin requirement is exactly:

1. Banner
2. Interstitial after successfully publishing a post
3. Native Advanced

DO NOT add Rewarded Ads.
DO NOT add App Open Ads.
DO NOT add mediation.
DO NOT add partner bidding.
DO NOT add unnecessary ad formats.

==================================================
1. GOOGLE MOBILE ADS SDK
==================================================

Add the official Flutter Google Mobile Ads package:

google_mobile_ads

Use the current stable version compatible with the project's existing Flutter/Dart version.

Do NOT arbitrarily upgrade Flutter, Dart, Gradle, Kotlin, Android Gradle Plugin, or other major dependencies just to install the package.

If the currently compatible google_mobile_ads version requires a specific dependency adjustment, make the minimum necessary change.

Run dependency resolution after modifying pubspec.yaml.

==================================================
2. ADMOB INITIALIZATION
==================================================

Initialize the Google Mobile Ads SDK correctly.

The SDK should be initialized once during application startup.

Do not initialize it repeatedly every time a screen opens.

Find the application's actual startup entry point and integrate initialization there.

Handle initialization safely.

Do not block the entire app startup unnecessarily if AdMob initialization takes time.

==================================================
3. ANDROID ADMOB APP ID
==================================================

Configure the Android AdMob App ID correctly.

Android App ID:

ca-app-pub-6848080783292385~6565575168

This must be placed in the appropriate AndroidManifest.xml metadata location required by google_mobile_ads.

Do not confuse the App ID with the individual Ad Unit IDs.

IMPORTANT DISTINCTION:

App ID:
ca-app-pub-6848080783292385~6565575168

Banner Ad Unit:
ca-app-pub-6848080783292385/7997699035

Interstitial Ad Unit:
ca-app-pub-6848080783292385/5739578658

Native Ad Unit:
ca-app-pub-6848080783292385/7115862201

==================================================
4. CENTRALIZED AD CONFIGURATION
==================================================

Create a clean centralized AdMob configuration.

For example, create something similar to:

lib/config/ad_config.dart

But first inspect the existing project architecture and use the project's established configuration/constants structure if one already exists.

The configuration should make it easy to switch between:

DEVELOPMENT:
Google test IDs

PRODUCTION:
My real AdMob IDs

Do NOT scatter ad unit IDs throughout the codebase.

Use a clear environment/build-mode mechanism if the project already has one.

If the project does not have one, use a simple safe mechanism based on kReleaseMode or an equivalent approach.

Development/debug/profile builds should use test IDs.

Release builds should be capable of using production IDs.

However, do NOT activate production ads in a way that makes local testing dangerous.

==================================================
5. BANNER ADS
==================================================

Implement Banner ads using google_mobile_ads.

The existing bSmart UI should not be redesigned.

First inspect the application and identify appropriate locations where a banner can be displayed without disrupting the existing UX.

Do not insert banners randomly into every screen.

Prefer a reusable BannerAd widget/component.

Requirements:

- Load the banner asynchronously.
- Handle loading failures.
- Dispose the BannerAd correctly.
- Avoid memory leaks.
- Do not repeatedly create BannerAd instances unnecessarily.
- Handle widget lifecycle correctly.
- Do not show a broken/empty ad container indefinitely when loading fails.
- Do not crash if AdMob is unavailable.
- Respect safe areas and existing layouts.

If there is already a feed/home page that is clearly intended for monetization, use an appropriate existing location.

Do not redesign the feed.

If you are uncertain about the best placement, inspect the UI architecture and choose the least disruptive reasonable location.

==================================================
6. INTERSTITIAL AD
==================================================

This is VERY IMPORTANT.

The requirement is:

SHOW AN INTERSTITIAL AFTER A USER SUCCESSFULLY PUBLISHES A POST.

Find the actual post publishing/creation flow in the existing application.

Do NOT guess which button is the publishing button.

Trace the actual flow, including:

- post creation screen
- submit/publish action
- API/service/repository call
- success response
- failure response
- navigation after successful publishing

The interstitial must only be shown AFTER the post has been successfully published.

Correct sequence:

User taps Publish
        ↓
Post API/upload executes
        ↓
Publishing succeeds
        ↓
Confirm success
        ↓
Load/show interstitial
        ↓
Continue existing post-publish navigation/flow

If publishing fails:

User taps Publish
        ↓
API/upload fails
        ↓
Show existing error handling
        ↓
DO NOT SHOW INTERSTITIAL

Do not show an interstitial merely because the user opened the create-post screen.

Do not show an interstitial before the API confirms success.

Do not interrupt the actual upload/publishing process.

==================================================
INTERSTITIAL IMPLEMENTATION DETAILS
==================================================

Create a reusable service/helper/controller for interstitial ads if that fits the existing architecture.

The implementation should:

- Load the interstitial.
- Detect load failures.
- Show it only when available.
- Handle full-screen content callbacks.
- Dispose/clear references correctly.
- Reload a new interstitial after one has been consumed if appropriate.
- Avoid showing the same ad instance more than once.
- Never crash if an ad fails to load.
- Never prevent the user from continuing if an ad cannot be shown.

VERY IMPORTANT:

If the interstitial fails to load, the user's post publishing flow must still continue normally.

Ads are optional monetization, not a dependency for publishing a post.

The existing success navigation must continue even if no ad is available.

If the current post publishing flow immediately navigates away from the screen, integrate the ad carefully so that showing it does not break navigation or cause a disposed-context exception.

Prefer a robust architecture where the publishing success event triggers the ad, while the rest of the existing flow remains intact.

==================================================
7. NATIVE ADVANCED ADS
==================================================

Implement Google Mobile Ads Native Advanced ads.

Production Native Ad Unit ID:

ca-app-pub-6848080783292385/7115862201

Development Native Test ID:

ca-app-pub-3940256099942544/2247696110

First inspect the existing bSmart UI.

The Native Advanced ad should be placed in a location where it naturally fits the application's content/feed experience.

Likely candidates include:

- social feed
- content feed
- discovery feed
- scrolling content list

But DO NOT assume this without inspecting the code.

Use an existing feed/content architecture where possible.

Do not redesign existing cards.

Create a reusable native ad widget.

The native ad implementation should:

- Load asynchronously.
- Handle loading errors.
- Dispose correctly.
- Avoid memory leaks.
- Work correctly inside a scrolling ListView/Sliver/List.
- Not create an excessive number of native ad instances.
- Not crash when scrolling quickly.
- Not leave broken placeholders permanently visible.
- Follow Google AdMob Native Ad policy requirements.
- Clearly distinguish the ad from organic content where required.
- Use proper NativeAd assets such as headline, body, icon, call-to-action, advertiser, media, etc. where supported.
- Follow the current google_mobile_ads Flutter native ad implementation pattern.

If the project already has a reusable feed-card component, integrate the native ad in a way that minimizes architectural changes.

==================================================
8. DO NOT BREAK EXISTING FUNCTIONALITY
==================================================

This is an existing production-oriented application.

Do NOT:

- rewrite the app
- change navigation unnecessarily
- change API contracts
- change backend APIs
- change authentication
- change Firebase logic
- change post publishing API behavior
- change unrelated UI
- remove dependencies unnecessarily
- change package name/application ID
- change signing configuration
- change Firebase configuration
- change iOS configuration while implementing Android AdMob unless required for shared Dart code
- modify unrelated screens

Only make changes necessary for AdMob integration.

==================================================
9. FIREBASE
==================================================

The application may already use Firebase.

Inspect the project first.

Do not add Firebase again if it is already configured.

Do not remove or replace existing Firebase configuration.

AdMob and Firebase may coexist.

If analytics/Firebase integration is already present, preserve it.

==================================================
10. ERROR HANDLING
==================================================

Ads must NEVER crash the app.

Handle:

- ad load failure
- no fill
- network failure
- disposed widget
- failed native ad rendering
- failed interstitial load
- interstitial dismissal
- app lifecycle changes
- navigation during ad loading
- user leaving the screen
- repeated widget rebuilds

Use proper logging during development.

Do not expose sensitive information in logs.

==================================================
11. TESTING
==================================================

After implementation:

Run:

flutter pub get

Then run:

flutter analyze

Fix all new errors/warnings caused by your changes.

Then run the appropriate tests/build commands available for the project.

Test on a real Android device if available.

Verify:

A. App starts normally.

B. AdMob SDK initializes.

C. Banner loads using the TEST Banner ID.

D. Native Advanced test ad loads using the TEST Native ID.

E. Create/publish post flow still works.

F. Successful post publishing triggers the TEST Interstitial.

G. Failed post publishing does NOT trigger an interstitial.

H. If the interstitial fails to load, the post flow still completes normally.

I. Navigating away from screens does not cause setState-after-dispose or similar lifecycle errors.

J. Scrolling the feed does not produce crashes or excessive ad creation.

==================================================
12. PRODUCTION SAFETY
==================================================

DO NOT test by clicking my real production ads.

Use Google's test ad IDs during development.

Production IDs should only be used when the app is ready for release and I explicitly decide to switch to production.

Make the code clearly identify which IDs are test and which are production.

==================================================
13. ADMOB POLICY / UX
==================================================

The implementation should follow current Google AdMob policies.

Do not:

- encourage users to click ads
- place ads where they can be accidentally clicked
- disguise ads as normal user content
- place ads directly over interactive controls
- show excessive interstitials
- show an interstitial before the user has completed the intended action
- interfere with post publishing
- use deceptive ad labels

For Native Advanced ads, make the ad visually distinguishable from user-generated content.

==================================================
14. CODE QUALITY
==================================================

Follow the existing project's architecture and coding style.

Prefer:

- reusable widgets
- clear services/helpers
- proper lifecycle management
- null safety
- minimal coupling
- clean separation between ad configuration and UI
- comments only where they add value

Do not over-engineer the solution.

Do not create unnecessary abstractions if the project is simple.

==================================================
15. IMPORTANT: INSPECT FIRST
==================================================

Before making modifications, inspect at minimum:

- pubspec.yaml
- lib/main.dart or actual entry point
- AndroidManifest.xml
- Android Gradle configuration
- existing navigation
- post creation/publishing screen
- post repository/service/API call
- feed/home screen
- existing reusable widgets
- Firebase configuration
- current Flutter/Dart versions

Find the EXACT post publishing success point.

Do not assume.

==================================================
16. FINAL REPORT
==================================================

After implementation, give me a concise but detailed report containing:

1. Files created
2. Files modified
3. What was changed in each
4. Where AdMob SDK initialization happens
5. Where the Android App ID was configured
6. Where Banner is implemented
7. Where Interstitial is triggered after successful post publishing
8. Where Native Advanced is implemented
9. Which TEST IDs are being used
10. Where production IDs are stored
11. Whether production IDs are currently active or test IDs are active
12. Commands you ran
13. Any warnings/errors remaining
14. Any manual steps I still need to perform
15. How I can verify the ads on a real Android device

IMPORTANT:
Do not claim something is implemented unless you actually inspected and changed the relevant code.

If you encounter an ambiguity in the existing architecture, inspect more of the code before deciding.

Start by inspecting the existing project. Do not modify anything until you understand the current structure and the post publishing flow.


Publish tapped
     ↓
API call
     ↓
SUCCESS
     ↓
show interstitial if loaded
     ↓
continue existing flow

Publish tapped
     ↓
API call
     ↓
FAILURE
     ↓
existing error handling
     ↓
NO AD