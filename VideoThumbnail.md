# VideoThumbnail — Agent Notes

Scope: how the **Welcome → Recent Files** panel renders per-video thumbnails, and the contracts future SwiftData / model changes must respect.

> Read this before touching `RecentVideo`, the welcome recent-files row, or anything in `VideoThumbnailView.swift`.

---

## What exists today

| File | Role |
|---|---|
| `VideoPlayer/Views/VideoThumbnailView.swift` | Owns the cache + the SwiftUI view. **Only place** that imports `AVFoundation` for this feature. |
| `VideoPlayer/Views/WelcomeView.swift` | `RecentVideoRowContent` consumes `VideoThumbnailView`. Does **not** decode anything itself. |
| `VideoPlayer/Views/WelcomeStyles.swift` | `WelcomeLayout.recentRowThumbnailCornerRadius` — single source of truth for the thumbnail's corner radius. Frame size reuses `recentRowIconFrameSize`. |

## Public surface

```swift
final class VideoThumbnailCache: @unchecked Sendable {
    static let shared: VideoThumbnailCache
    func thumbnail(for url: URL, maximumSize: CGSize) async -> NSImage?
}

struct VideoThumbnailView: View {
    init(url: URL, size: CGFloat, cornerRadius: CGFloat, isHighlighted: Bool = false)
}
```

- `VideoThumbnailCache` is process-wide; do **not** instantiate per row.
- `VideoThumbnailView` self-loads via `.task(id: url)`. Falls back to `play.rectangle.fill` while loading or on failure.

## Caching behavior

- Backing store: `NSCache<NSURL, NSImage>`, `countLimit = 128`, thread-safe.
- Key: the **video URL** (as `NSURL`).
- Lifetime: in-memory only. **Wiped on app relaunch.** Each launch re-decodes thumbnails the first time a row appears.
- Sample frame: `min(duration * 0.1, 5s)` to skip black title cards. Falls back to `0.1s` if `duration` can't be loaded.
- Decode size: caller-supplied `maximumSize`; `VideoThumbnailView` passes `size * 3` for Retina headroom.

## Architecture invariants (do not regress)

1. Views must never touch `AVPlayer` / `AVAssetImageGenerator` directly. All AVFoundation usage stays inside `VideoThumbnailCache`. (Matches AGENTS.md "Views never touch AVPlayer".)
2. `WelcomeLayout` is the only place for sizes, paddings, corner radii. New visual knobs → add a constant there first.
3. The recent-row's existing hover plumbing (`@Environment(\.isHovered)` from `WelcomeStyles.swift`) is reused via the `isHighlighted` parameter — don't add a parallel hover system.

## SwiftData notes for upcoming changes

The current `RecentVideo` model is unchanged:

```swift
@Model final class RecentVideo {
    var id: UUID
    var url: URL
    var title: String
    var lastOpened: Date
}
```

When extending the model, mind these rules:

- **If you persist thumbnails on the model** (e.g., add `var thumbnailData: Data?`):
  - Render path becomes: model field → fallback to `VideoThumbnailCache` → fallback to placeholder.
  - Generate **once at insertion** (e.g., in `ContentView.saveRecentVideo`). Do not regenerate on every view appear.
  - Cap stored size (e.g., 240px on the long side, JPEG ~70%) to keep the store small.
  - Keep `VideoThumbnailCache` around — it's still the fastest path for newly added videos before the model write commits.

- **If you switch `url: URL` to a security-scoped bookmark `Data`**:
  - Resolve to a URL inside `VideoThumbnailCache.thumbnail(for:)` before constructing `AVURLAsset`.
  - Don't leak the bookmark resolution onto the main actor unless necessary — keep the cache callable from `Task.detached` contexts.
  - The cache key must become stable across resolutions (use the bookmark's `id`/UUID, not the resolved URL, which can change).

- **If you add a `var deletedAt: Date?` / soft-delete column**: filter at the `@Query` predicate level; the thumbnail layer doesn't need to know.

- **If you add per-video metadata (duration, codec, dimensions)**:
  - Extract during the same `AVAssetImageGenerator` pass — load `.duration`, `.tracks`, `.naturalSize` from the asset in one async batch and persist alongside `RecentVideo`. Avoid making a second AVFoundation pass.
  - Then `VideoThumbnailCache` can shrink: only the image stays cached; metadata lives on the model.

## Known gaps / good first follow-ups

- **No disk cache.** Cold launch regenerates all visible thumbnails. Add a `~/Library/Caches/<bundle id>/thumbnails/<sha256(url)>.jpg` layer behind `VideoThumbnailCache` before going to disk SwiftData.
- **No file-existence check.** If the file moved/was deleted, generation silently fails and the placeholder shows. Consider surfacing a "missing" badge — but probably wait until you add deletion / pruning of stale `RecentVideo` rows.
- **Square crop only.** Frame is `recentRowIconFrameSize × recentRowIconFrameSize` (40×40). To switch to 16:9, change `VideoThumbnailView.size` to a `CGSize` and add a `recentRowThumbnailSize: CGSize` to `WelcomeLayout`.
- **Unbounded concurrent decodes.** When the list is large, all visible rows decode in parallel. If perf becomes an issue, gate the cache with an `AsyncSemaphore` (or actor with a serial task queue).

## Touched files (commit `a362dc0`)

- `VideoPlayer/Views/VideoThumbnailView.swift` *(new, ~95 LoC)*
- `VideoPlayer/Views/WelcomeView.swift` *(swap icon for `VideoThumbnailView`)*
- `VideoPlayer/Views/WelcomeStyles.swift` *(add `recentRowThumbnailCornerRadius`)*
