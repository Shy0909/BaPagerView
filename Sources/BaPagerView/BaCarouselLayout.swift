import UIKit

/// Geometry is shared by snapping and layout transforms, so both use the same anchor.
internal final class BaCarouselLayout: UICollectionViewFlowLayout {
    var settings = BaCarouselConfiguration()

    override init() {
        super.init()
        scrollDirection = .horizontal
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        scrollDirection = .horizontal
    }

    var step: CGFloat {
        itemSize.width + minimumLineSpacing
    }

    var cellAnchorOffset: CGFloat {
        switch settings.alignment {
        case .left: return 0
        case .center: return itemSize.width / 2
        case .right: return itemSize.width
        }
    }

    var viewportAnchor: CGFloat {
        guard let collectionView = collectionView else { return 0 }
        let width = collectionView.bounds.width
        switch settings.alignment {
        case .left: return max(0, min(width, settings.alignmentOffset))
        case .center: return max(0, min(width, width / 2 + settings.alignmentOffset))
        case .right: return max(0, min(width, width - settings.alignmentOffset))
        }
    }

    func updateGeometry(in size: CGSize, infinite: Bool) {
        let width = settings.itemSize.width > 0 ? settings.itemSize.width : size.width
        let height = settings.itemSize.height > 0 ? settings.itemSize.height : size.height
        let newItemSize = CGSize(width: max(0, width), height: max(0, height))
        let spacing = max(0, settings.itemSpacing)
        let vertical = max(0, (size.height - newItemSize.height) / 2)
        let cellAnchor: CGFloat
        let viewportAnchor: CGFloat
        switch settings.alignment {
        case .left:
            cellAnchor = 0
            viewportAnchor = max(0, min(size.width, settings.alignmentOffset))
        case .center:
            cellAnchor = newItemSize.width / 2
            viewportAnchor = max(0, min(size.width, size.width / 2 + settings.alignmentOffset))
        case .right:
            cellAnchor = newItemSize.width
            viewportAnchor = max(0, min(size.width, size.width - settings.alignmentOffset))
        }
        let left = infinite ? 0 : max(0, viewportAnchor - cellAnchor)
        let right = infinite ? 0 : max(0, size.width - viewportAnchor - (newItemSize.width - cellAnchor))
        let inset = UIEdgeInsets(top: vertical, left: left, bottom: vertical, right: right)
        if itemSize != newItemSize || minimumLineSpacing != spacing || sectionInset != inset {
            itemSize = newItemSize
            minimumLineSpacing = spacing
            minimumInteritemSpacing = spacing
            sectionInset = inset
            invalidateLayout()
        }
    }

    func targetOffset(for physicalIndex: Int) -> CGFloat {
        sectionInset.left + CGFloat(physicalIndex) * step + cellAnchorOffset - viewportAnchor
    }

    func nearestPhysicalIndex(at offset: CGFloat, count: Int) -> Int {
        guard count > 0, step > 0 else { return 0 }
        let coordinate = (offset + viewportAnchor - sectionInset.left - cellAnchorOffset) / step
        return max(0, min(count - 1, Int(round(coordinate))))
    }

    func progress(for physicalIndex: Int, contentOffset: CGFloat) -> CGFloat {
        guard step > 0 else { return 0 }
        let distance = abs(targetOffset(for: physicalIndex) - contentOffset)
        return max(0, min(1, 1 - distance / step))
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        true
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = super.layoutAttributesForElements(in: rect) else { return nil }
        return attributes.map { original in
            let copy = original.copy() as! UICollectionViewLayoutAttributes
            applyEffect(to: copy)
            return copy
        }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let original = super.layoutAttributesForItem(at: indexPath) else { return nil }
        let copy = original.copy() as! UICollectionViewLayoutAttributes
        applyEffect(to: copy)
        return copy
    }

    private func applyEffect(to attributes: UICollectionViewLayoutAttributes) {
        guard attributes.representedElementCategory == .cell,
              let collectionView = collectionView else { return }
        let position = progress(for: attributes.indexPath.item,
                                contentOffset: collectionView.contentOffset.x)
        // Smoothstep gives zero slope at both ends, without a scale change at snap completion.
        let eased = position * position * (3 - 2 * position)
        let minimum = max(0.01, min(settings.minimumScale, settings.maximumScale))
        let maximum = max(minimum, settings.maximumScale)
        let scale = minimum + (maximum - minimum) * eased
        attributes.transform = CGAffineTransform(scaleX: scale, y: scale)
        attributes.zIndex = Int(position * 1000)
    }
}
