import UIKit

/// The point on a cell that is aligned with the matching point in the carousel.
@objc(BaCarouselAlignment)
public enum BaCarouselAlignment: Int {
    case left
    case center
    case right
}

/// Describes the direction in which the content moves during automatic scrolling.
@objc(BaCarouselAutoDirection)
public enum BaCarouselAutoDirection: Int {
    case left
    case right
}

/// Assign a configured instance to BaCarouselView.configuration to apply changes.
@objc(BaCarouselConfiguration)
@objcMembers
public final class BaCarouselConfiguration: NSObject, NSCopying {
    /// A zero width or height fills the corresponding dimension of the carousel.
    public var itemSize: CGSize = .zero
    public var itemSpacing: CGFloat = 0
    public var alignment: BaCarouselAlignment = .center
    /// Inward from an edge; for center alignment, positive values move right.
    public var alignmentOffset: CGFloat = 0
    public var minimumScale: CGFloat = 1
    public var maximumScale: CGFloat = 1
    /// Zero disables automatic scrolling.
    public var autoScrollInterval: TimeInterval = 0
    public var scrollAnimationDuration: TimeInterval = 0.35
    public var autoDirection: BaCarouselAutoDirection = .left
    public var isInfiniteLoop = false

    public override init() {
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let result = BaCarouselConfiguration()
        result.itemSize = itemSize
        result.itemSpacing = itemSpacing
        result.alignment = alignment
        result.alignmentOffset = alignmentOffset
        result.minimumScale = minimumScale
        result.maximumScale = maximumScale
        result.autoScrollInterval = autoScrollInterval
        result.scrollAnimationDuration = scrollAnimationDuration
        result.autoDirection = autoDirection
        result.isInfiniteLoop = isInfiniteLoop
        return result
    }
}
