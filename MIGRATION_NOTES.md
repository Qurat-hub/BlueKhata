# Dependency Conflict Resolution — Migration Notes

## Environment note (read first)

I don't have Flutter/Dart SDK or pub.dev access in the environment I edited
this project in, so I could not literally execute `flutter pub get`,
`flutter analyze`, `build_runner`, or `flutter test` to produce a live
pass/fail. Everything below is a static analysis of the actual dependency
graph and actual code usage (via `grep` across `lib/`), not a guess. Please
run the verification commands in the last section on your machine and treat
that as the real confirmation.

## Root cause

The project declared five codegen dev-dependencies:

- `hive_generator`
- `freezed` (the generator; `freezed_annotation` too)
- `riverpod_generator` (`riverpod_annotation` too)
- `json_serializable` (`json_annotation` too)
- `build_runner`

**None of them generate anything in this project.** A full grep of `lib/`
for their trigger annotations returns zero matches:

```
@HiveType / @HiveField / TypeAdapter   → 0 matches
@freezed / part '*.freezed.dart'       → 0 matches
@riverpod / part '*.g.dart'            → 0 matches
@JsonSerializable / @JsonKey           → 0 matches
```

All models (`Business`, `Customer`, `LedgerEntry`) are plain hand-written
Dart classes with manual `toMap()`/`fromMap()`. All Riverpod providers are
hand-written `Provider`/`StateNotifierProvider`/`FutureProvider` — no
`@riverpod` annotations anywhere. Hive is used via plain `Hive.openBox()`
generic boxes; the offline sync queue (`SyncQueueService`) already stores
`jsonEncode()`d maps as strings, i.e. the exact
`Model → toMap()/toJson() → Hive Box (string) → fromMap()/fromJson()`
pattern the task asked for — it just never needed generated adapters to
begin with.

So these five packages were pure dead weight, each pinning its own
`analyzer`/`source_gen`/(macros for newer generators) version range. This
is the same well-documented class of failure seen across the Flutter
ecosystem right now — `riverpod_generator` vs `isar_generator`,
`riverpod_generator` vs `auto_route_generator`, `hive_generator` pinned to
an old `analyzer` range that was never updated — combining any two
generator packages is fragile by design at the moment because each ships
independently and pins its own transitive `analyzer` constraint. There is
no version combination of all five that reliably resolves together; the
correct fix is architectural, not "try another version."

## What changed

### `pubspec.yaml`
Removed (all confirmed unused):
- `build_runner`
- `freezed` / `freezed_annotation`
- `json_serializable` / `json_annotation`
- `riverpod_generator` / `riverpod_annotation`
- `hive_generator`

Kept, unchanged in role:
- `flutter_riverpod` — providers stay exactly as written (manual style)
- `hive` / `hive_flutter` — runtime box storage, no adapters needed
- `supabase_flutter`, `go_router`, and every other feature package —
  none of these are codegen packages and none were part of the conflict

Bumped `environment.sdk` lower bound from `>=3.4.0` to `>=3.9.0` to track
current Dart syntax baselines. I could not verify the exact latest patch
versions of every package against pub.dev from this environment — after
removing the conflicting generators, run `flutter pub upgrade
--major-versions` once to pull the newest versions compatible with your
installed Flutter 3.44.6 / Dart 3.12.2, then re-lock.

### No other files changed
No `lib/` source file imported any of the five removed packages, so there
is no code to refactor. No `*.g.dart`, `*.freezed.dart`, or `*.gr.dart`
files existed to delete — `build_runner` was never actually run against
this codebase.

## Modified files

| File | Change |
|---|---|
| `pubspec.yaml` | Removed 5 unused codegen dev-dependencies + their annotation packages; bumped SDK lower bound |
| `MIGRATION_NOTES.md` | New — this file |

## Migration notes for Hive (why none were needed)

There were no `@HiveType`/`@HiveField` classes or generated `TypeAdapter`s
to migrate away from — `HiveBoxes` in
`lib/core/services/local_storage_service.dart` already opens untyped boxes,
and `SyncQueueService.enqueue()` already writes `jsonEncode(task.toJson())`
strings into them, reading them back with `jsonDecode(...)` in
`SyncTask.fromJson`. That's the target architecture already in place:

```
Supabase → plain Dart model → toMap()/toJson() → Hive Box (String/Map) → fromMap()/fromJson()
```

If you add new cached entities later (e.g. caching `Customer` lists for
offline read), follow the same pattern: give the model a `toMap()`/
`fromMap()` pair by hand (they already exist on `Business`, `Customer`,
`LedgerEntry`) and store `jsonEncode(model.toMap())` in the relevant box
(`HiveBoxes.customersCache`, etc.) — no generator required.

## If you genuinely need a generator later

Riverpod and Freezed codegen are real productivity tools and this removal
doesn't rule them out forever — it just means "don't combine three of them
blindly." If a future feature needs one:

1. Add **one** generator package back at a time.
2. Run `flutter pub get` and confirm it resolves *before* writing any code
   against it.
3. Only then consider adding a second generator, and re-check resolution
   after each addition — don't add all three speculatively again.

Given how fragile multi-generator graphs are right now, the pragmatic
recommendation for this project is to keep the current hand-written style
(manual providers, manual model classes) rather than reintroducing codegen
purely for its own sake.

## Verification steps (run on your machine — Flutter 3.44.6 / Dart 3.12.2)

```bash
flutter clean
flutter pub get
flutter pub upgrade --major-versions   # optional: pull latest compatible patch/majors
flutter analyze
flutter test                            # no tests exist yet in this scaffold
```

Since no `build_runner`-generated code exists or is needed, there is no
`flutter pub run build_runner build` step required anymore. If `flutter
pub get` still reports a conflict after this change, it will be coming
from a *non-codegen* package version mismatch (e.g. a plugin requiring a
newer Flutter than 3.44.6) — paste the exact resolver error and I'll trace
that specific edge from the graph.
