import SwiftUI

#if os(macOS)
import AppKit
import AVFoundation

/// Process-wide cache for generated video thumbnails.
///
/// Lives outside of any individual view because `@State` thumbnails inside a
/// `List` get torn down when rows scroll off-screen — without a shared cache
/// every redraw would re-decode the asset. `NSCache` is thread-safe, so we can
/// hand the same instance to many concurrent tasks safely.
final class VideoThumbnailCache: @unchecked Sendable {
    static let shared = VideoThumbnailCache()

    private let cache: NSCache<NSURL, NSImage> = {
        let c = NSCache<NSURL, NSImage>()
        c.countLimit = 128
        return c
    }()

    private init() {}

    func thumbnail(for url: URL, maximumSize: CGSize) async -> NSImage? {
        if let hit = cache.object(forKey: url as NSURL) {
            return hit
        }

        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = maximumSize

        let sampleTime = await Self.preferredSampleTime(for: asset)

        do {
            let (cgImage, _) = try await generator.image(at: sampleTime)
            let image = NSImage(cgImage: cgImage, size: .zero)
            cache.setObject(image, forKey: url as NSURL)
            return image
        } catch {
            return nil
        }
    }

    /// Sample around 10% into the asset (capped at 5s) so we avoid black
    /// title cards while still landing near the visual identity of the video.
    private static func preferredSampleTime(for asset: AVURLAsset) async -> CMTime {
        do {
            let duration = try await asset.load(.duration)
            let target = max(min(duration.seconds * 0.1, 5.0), 0.0)
            return CMTime(seconds: target, preferredTimescale: 600)
        } catch {
            return CMTime(seconds: 0.1, preferredTimescale: 600)
        }
    }
}

/// Renders a square thumbnail for the video at `url`, falling back to a film
/// glyph while loading or if frame extraction fails (e.g., missing file).
struct VideoThumbnailView: View {
    let url: URL
    let size: CGFloat
    let cornerRadius: CGFloat
    var isHighlighted: Bool = false

    @State private var image: NSImage?

    var body: some View {
        ZStack {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color.black.opacity(0.25)
                    Image(systemName: "play.rectangle.fill")
                        .font(.title3)
                        .foregroundStyle(isHighlighted ? .white : .secondary)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(isHighlighted ? 0.35 : 0.12),
                              lineWidth: 0.5)
        )
        .task(id: url) {
            image = await VideoThumbnailCache.shared.thumbnail(
                for: url,
                maximumSize: CGSize(width: size * 3, height: size * 3)
            )
        }
    }
}

#endif
