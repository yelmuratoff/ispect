# TODO

---

## Network / HTTP clients

### Existing

- [x] ispectify_dio (Dio interceptor)
- [x] ispectify_http (http package interceptor)
- [x] ispectify_ws (WebSocket traffic capture)

### Planned

- [ ] Chopper interceptor
- [ ] Retrofit interceptor (dio-based, может покрываться ispectify_dio)
- [ ] gRPC interceptor (ClientInterceptor)
- [ ] GraphQL interceptor (graphql_flutter / ferry / artemis)

---

## Local databases (ispectify_db)

### Existing

- [x] Drift / sqflite (QueryExecutor wrapper)
- [x] Hive interceptor
- [x] Isar interceptor
- [x] ObjectBox interceptor
- [x] Realm interceptor
- [x] GetStorage interceptor
- [x] SharedPreferences interceptor

### Planned

- [ ] flutter_cache_manager interceptor
- [ ] Sembast interceptor

---

## Remote DB drivers — TCP/socket (ispectify_db)

- [ ] Postgres (postgres / postgrest) interceptor
- [ ] MongoDB (mongo_dart) interceptor
- [ ] Redis interceptor

---

## BaaS / SDK wrappers (decorator pattern)

SDK-обёртки вокруг клиентских библиотек (как ISpectFirestoreCollection).

### Firebase

- [x] Firestore (ISpectFirestoreCollection / ISpectFirestoreDocument)
- [ ] Firebase Realtime Database
- [ ] Firebase Auth (sign in / sign out / token refresh events)
- [ ] Firebase Storage (upload / download progress)
- [ ] Firebase Messaging (FCM push received / opened)
- [ ] Firebase Remote Config (fetch / activate)
- [ ] Firebase Analytics (event forwarding / logging)
- [ ] Firebase Crashlytics (non-fatal error forwarding)

### Supabase

- [ ] Supabase Database (PostgREST queries)
- [ ] Supabase Auth
- [ ] Supabase Storage
- [ ] Supabase Realtime (WebSocket channels)

### Other BaaS

- [ ] Appwrite (DB, Auth, Storage, Realtime)
- [ ] PocketBase (DB, Auth, Realtime)
- [ ] AWS Amplify (DataStore, Auth, Storage)
- [ ] PowerSync interceptor

---

## State management (observers)

### Existing

- [x] ispectify_bloc (BLoC / Cubit observer)

### Planned

- [ ] Riverpod observer (ProviderObserver wrapper)
- [ ] MobX spy interceptor
- [ ] Redux middleware
- [ ] GetX observer

---

## Navigation / Routing

### Existing

- [x] ISpectNavigatorObserver (Navigator 2.0)

### Planned

- [ ] GoRouter observer / logging
- [ ] AutoRoute observer

---

## Push notifications

- [ ] FCM (Firebase Messaging) — see Firebase section
- [ ] OneSignal interceptor
- [ ] flutter_local_notifications interceptor

---

## Analytics / Crash reporting

- [ ] Firebase Analytics — see Firebase section
- [ ] Firebase Crashlytics — see Firebase section
- [ ] Sentry breadcrumb integration
- [ ] Mixpanel event interceptor
- [ ] Amplitude event interceptor

---

## Auth providers

- [ ] Firebase Auth — see Firebase section
- [ ] Supabase Auth — see Supabase section
- [ ] google_sign_in flow logging
- [ ] sign_in_with_apple flow logging

---

## Image / Media

- [ ] cached_network_image (cache hits/misses, load times)
- [ ] flutter_image_compress operations logging

---

## Background tasks

- [ ] WorkManager task logging
- [ ] background_fetch event logging

---

## Payments

- [ ] in_app_purchase transaction logging
- [ ] RevenueCat event interceptor

---

## Architecture / Internal

- [ ] Move core UI logic from ispect to ispect_widget package

---

## Testing

- [ ] Increase test coverage from current ~11% to >80%
- [ ] Add unit tests for:
  - [ ] File I/O operations
  - [ ] JSON serialization
  - [ ] Filtering logic
  - [ ] Redaction service
  - [ ] Session management
- [ ] Create test utilities/fixtures for common scenarios
- [ ] Set up code coverage reporting in CI/CD

---
