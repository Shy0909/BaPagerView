import UIKit

@objc(BaCarouselViewDataSource)
public protocol BaCarouselViewDataSource: NSObjectProtocol {
    @objc(numberOfItemsInCarouselView:)
    func numberOfItems(in carouselView: BaCarouselView) -> Int

    @objc(carouselView:cellForItemAtIndex:)
    func carouselView(_ carouselView: BaCarouselView, cellForItemAt index: Int) -> UICollectionViewCell
}

@objc(BaCarouselViewDelegate)
public protocol BaCarouselViewDelegate: NSObjectProtocol {
    @objc(carouselView:didSelectItemAtIndex:)
    optional func carouselView(_ carouselView: BaCarouselView, didSelectItemAt index: Int)

    /// Called only after dragging or an animated scroll has settled.
    @objc(carouselView:didSettleAtIndex:)
    optional func carouselView(_ carouselView: BaCarouselView, didSettleAt index: Int)

    /// Progress is 1 at the snap anchor and 0 one item step away.
    @objc(carouselView:didUpdateCell:atIndex:progress:)
    optional func carouselView(_ carouselView: BaCarouselView,
                               didUpdate cell: UICollectionViewCell,
                               at index: Int,
                               progress: CGFloat)
}

private final class BaCarouselDisplayLinkProxy: NSObject {
    weak var owner: BaCarouselView?

    @objc func tick(_ link: CADisplayLink) {
        guard let owner = owner else {
            link.invalidate()
            return
        }
        owner.advanceAnimation()
    }
}

/// A reusable horizontal carousel. Supply and retain business data in the data source.
@objc(BaCarouselView)
public final class BaCarouselView: UIView, UICollectionViewDataSource, UICollectionViewDelegate {
    @objc public weak var dataSource: BaCarouselViewDataSource?
    @objc public weak var delegate: BaCarouselViewDelegate?

    /// Reassign a configuration after changing it; the getter returns a copy.
    @objc public var configuration: BaCarouselConfiguration {
        get { settings.copy() as! BaCarouselConfiguration }
        set { applyConfiguration(newValue) }
    }

    /// NSNotFound when there is no item.
    @objc public private(set) var currentIndex: Int = NSNotFound

    /// Useful when the carousel remains in a window inside an offscreen reusable cell.
    @objc public var isAutoScrollPaused = false {
        didSet {
            if isAutoScrollPaused {
                stopTimer()
                cancelAnimation()
                if !collectionView.isDragging && !collectionView.isDecelerating {
                    settle()
                }
            } else {
                scheduleAutoScroll()
            }
        }
    }

    private let carouselLayout = BaCarouselLayout()
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: carouselLayout)
        view.dataSource = self
        view.delegate = self
        view.backgroundColor = .clear
        view.showsHorizontalScrollIndicator = false
        view.alwaysBounceVertical = false
        view.contentInsetAdjustmentBehavior = .never
        view.clipsToBounds = false
        return view
    }()

    private var settings = BaCarouselConfiguration()
    private var itemCount = 0
    private var physicalCount = 0
    private var selectedPhysicalIndex = 0
    private var activeDequeuingPath: IndexPath?
    private var needsInitialPosition = false
    private var isReloading = false
    private var isRecentering = false
    private var isInBackground = false
    private var lastBoundsSize: CGSize = .zero

    private var autoTimer: Timer?
    private let displayLinkProxy = BaCarouselDisplayLinkProxy()
    private var displayLink: CADisplayLink?
    private var animationStartTime: CFTimeInterval = 0
    private var animationStartOffset: CGFloat = 0
    private var animationTargetOffset: CGFloat = 0

    private var infiniteEnabled: Bool {
        settings.isInfiniteLoop && itemCount > 1 && itemCount <= Int.max / 5 && physicalCount == itemCount * 5
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    deinit {
        stopTimer()
        cancelAnimation()
        NotificationCenter.default.removeObserver(self)
    }

    private func commonInit() {
        clipsToBounds = false
        displayLinkProxy.owner = self
        addSubview(collectionView)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.frame = bounds
        let sizeChanged = lastBoundsSize != bounds.size
        if sizeChanged || needsInitialPosition {
            if sizeChanged { cancelAnimation() }
            lastBoundsSize = bounds.size
            carouselLayout.updateGeometry(in: bounds.size, infinite: infiniteEnabled)
            collectionView.layoutIfNeeded()
            if needsInitialPosition {
                positionAtCurrentIndexIfPossible()
            } else if sizeChanged && itemCount > 0 && bounds.width > 0 {
                let target = boundedOffset(carouselLayout.targetOffset(for: selectedPhysicalIndex))
                collectionView.setContentOffset(CGPoint(x: target, y: 0), animated: false)
                reportVisibleProgress()
                scheduleAutoScroll()
            }
        }
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            stopTimer()
            cancelAnimation()
        } else {
            if itemCount > 0 && !collectionView.isDragging && !collectionView.isDecelerating {
                settle()
            } else {
                scheduleAutoScroll()
            }
        }
    }

    @objc(applyConfiguration:)
    public func applyConfiguration(_ configuration: BaCarouselConfiguration) {
        assert(Thread.isMainThread)
        settings = configuration.copy() as! BaCarouselConfiguration
        carouselLayout.settings = settings
        reloadData()
    }

    @objc(registerClass:forCellWithReuseIdentifier:)
    public func register(_ cellClass: AnyClass, forCellWithReuseIdentifier identifier: String) {
        assert(Thread.isMainThread)
        collectionView.register(cellClass, forCellWithReuseIdentifier: identifier)
    }

    /// Call only inside carouselView:cellForItemAtIndex: with that logical index.
    @objc(dequeueReusableCellWithReuseIdentifier:forIndex:)
    public func dequeueReusableCell(withReuseIdentifier identifier: String, for index: Int) -> UICollectionViewCell {
        guard let path = activeDequeuingPath, logicalIndex(for: path.item) == index else {
            preconditionFailure("Dequeue a carousel cell only from the matching data-source callback")
        }
        return collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: path)
    }

    @objc(reloadData)
    public func reloadData() {
        assert(Thread.isMainThread)
        stopTimer()
        cancelAnimation()
        isReloading = true
        let previousIndex = currentIndex
        itemCount = max(0, dataSource?.numberOfItems(in: self) ?? 0)
        physicalCount = settings.isInfiniteLoop && itemCount > 1 && itemCount <= Int.max / 5
            ? itemCount * 5 : itemCount
        currentIndex = itemCount == 0 ? NSNotFound : min(previousIndex == NSNotFound ? 0 : previousIndex, itemCount - 1)
        selectedPhysicalIndex = infiniteEnabled ? itemCount * 2 + currentIndex : (itemCount == 0 ? 0 : currentIndex)
        needsInitialPosition = itemCount > 0
        carouselLayout.settings = settings
        carouselLayout.updateGeometry(in: bounds.size, infinite: infiniteEnabled)
        collectionView.reloadData()
        if itemCount == 0 {
            collectionView.setContentOffset(.zero, animated: false)
        }
        collectionView.layoutIfNeeded()
        isReloading = false
        setNeedsLayout()
        layoutIfNeeded()
        positionAtCurrentIndexIfPossible()
        scheduleAutoScroll()
    }

    @objc(scrollToItemAtIndex:animated:)
    public func scrollToItem(at index: Int, animated: Bool) {
        assert(Thread.isMainThread)
        guard index >= 0, index < itemCount else { return }
        stopTimer()
        cancelAnimation()
        guard !needsInitialPosition, carouselLayout.step > 0 else {
            currentIndex = index
            selectedPhysicalIndex = infiniteEnabled ? itemCount * 2 + index : index
            needsInitialPosition = true
            setNeedsLayout()
            return
        }
        let physical = nearestPhysicalIndex(for: index)
        scrollToPhysicalIndex(physical, animated: animated)
    }

    private func positionAtCurrentIndexIfPossible() {
        guard needsInitialPosition, itemCount > 0, bounds.width > 0,
              collectionView.bounds.width > 0,
              carouselLayout.step > 0 else { return }
        let offset = boundedOffset(carouselLayout.targetOffset(for: selectedPhysicalIndex))
        collectionView.setContentOffset(CGPoint(x: offset, y: 0), animated: false)
        needsInitialPosition = false
        reportVisibleProgress()
        scheduleAutoScroll()
    }

    private func logicalIndex(for physicalIndex: Int) -> Int {
        guard itemCount > 0 else { return NSNotFound }
        return physicalIndex % itemCount
    }

    private func nearestPhysicalIndex(for logicalIndex: Int) -> Int {
        guard infiniteEnabled else { return logicalIndex }
        let currentPhysical = carouselLayout.nearestPhysicalIndex(at: collectionView.contentOffset.x,
                                                                 count: physicalCount)
        let baseSection = currentPhysical / itemCount
        let candidates = [baseSection - 1, baseSection, baseSection + 1]
            .filter { (0..<5).contains($0) }
            .map { $0 * itemCount + logicalIndex }
        return candidates.min { abs($0 - currentPhysical) < abs($1 - currentPhysical) } ?? logicalIndex
    }

    private func boundedOffset(_ offset: CGFloat) -> CGFloat {
        let maximum = max(0, collectionView.contentSize.width - collectionView.bounds.width)
        return max(0, min(maximum, offset))
    }

    private func scrollToPhysicalIndex(_ physicalIndex: Int, animated: Bool) {
        let target = boundedOffset(carouselLayout.targetOffset(for: physicalIndex))
        let duration = max(0, settings.scrollAnimationDuration)
        if !animated || duration == 0 || abs(target - collectionView.contentOffset.x) < 0.5 {
            collectionView.setContentOffset(CGPoint(x: target, y: 0), animated: false)
            settle()
            return
        }
        animationStartOffset = collectionView.contentOffset.x
        animationTargetOffset = target
        animationStartTime = CACurrentMediaTime()
        let link = CADisplayLink(target: displayLinkProxy, selector: #selector(BaCarouselDisplayLinkProxy.tick(_:)))
        displayLink = link
        link.add(to: .main, forMode: .common)
    }

    fileprivate func advanceAnimation() {
        let duration = max(0.001, settings.scrollAnimationDuration)
        let fraction = CGFloat(min(1, (CACurrentMediaTime() - animationStartTime) / duration))
        let eased = fraction * fraction * (3 - 2 * fraction)
        let offset = animationStartOffset + (animationTargetOffset - animationStartOffset) * eased
        collectionView.setContentOffset(CGPoint(x: offset, y: 0), animated: false)
        if fraction >= 1 {
            cancelAnimation()
            settle()
        }
    }

    private func cancelAnimation() {
        displayLink?.invalidate()
        displayLink = nil
    }

    private func recenterIfNeeded() {
        guard infiniteEnabled, !isRecentering, carouselLayout.step > 0 else { return }
        let physical = carouselLayout.nearestPhysicalIndex(at: collectionView.contentOffset.x,
                                                           count: physicalCount)
        let shift: Int
        if physical < itemCount {
            shift = itemCount * 2
        } else if physical >= itemCount * 4 {
            shift = -itemCount * 2
        } else {
            return
        }
        isRecentering = true
        selectedPhysicalIndex += shift
        collectionView.contentOffset.x += CGFloat(shift) * carouselLayout.step
        isRecentering = false
    }

    private func settle() {
        guard itemCount > 0, carouselLayout.step > 0 else { return }
        var physical = carouselLayout.nearestPhysicalIndex(at: collectionView.contentOffset.x,
                                                           count: physicalCount)
        let index = logicalIndex(for: physical)
        if infiniteEnabled {
            // Identical content at the same visual position; leave room to scroll either way.
            let middle = itemCount * 2 + index
            let target = boundedOffset(carouselLayout.targetOffset(for: middle))
            if physical != middle || abs(collectionView.contentOffset.x - target) > 0.5 {
                collectionView.setContentOffset(CGPoint(x: target, y: 0), animated: false)
                physical = middle
            }
        } else {
            let target = boundedOffset(carouselLayout.targetOffset(for: physical))
            if abs(collectionView.contentOffset.x - target) > 0.5 {
                collectionView.setContentOffset(CGPoint(x: target, y: 0), animated: false)
            }
        }
        selectedPhysicalIndex = physical
        if index != currentIndex {
            currentIndex = index
            delegate?.carouselView?(self, didSettleAt: index)
        }
        reportVisibleProgress()
        scheduleAutoScroll()
    }

    private func reportVisibleProgress() {
        guard itemCount > 0 else { return }
        for path in collectionView.indexPathsForVisibleItems {
            guard let cell = collectionView.cellForItem(at: path) else { continue }
            let progress = carouselLayout.progress(for: path.item,
                                                   contentOffset: collectionView.contentOffset.x)
            delegate?.carouselView?(self, didUpdate: cell,
                                    at: logicalIndex(for: path.item), progress: progress)
        }
    }

    private func scheduleAutoScroll() {
        stopTimer()
        guard window != nil, !isInBackground, !isAutoScrollPaused,
              itemCount > 1, settings.autoScrollInterval > 0,
              !collectionView.isDragging, !collectionView.isDecelerating,
              displayLink == nil, !needsInitialPosition else { return }
        if !infiniteEnabled &&
            ((settings.autoDirection == .left && currentIndex == itemCount - 1) ||
             (settings.autoDirection == .right && currentIndex == 0)) { return }
        let timer = Timer(timeInterval: settings.autoScrollInterval, repeats: false) { [weak self] _ in
            self?.advanceAutomatically()
        }
        autoTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func stopTimer() {
        autoTimer?.invalidate()
        autoTimer = nil
    }

    private func advanceAutomatically() {
        autoTimer = nil
        guard itemCount > 1, !isAutoScrollPaused, window != nil else { return }
        let direction = settings.autoDirection == .left ? 1 : -1
        if infiniteEnabled {
            scrollToPhysicalIndex(selectedPhysicalIndex + direction, animated: true)
        } else {
            let next = currentIndex + direction
            guard (0..<itemCount).contains(next) else { return }
            scrollToPhysicalIndex(next, animated: true)
        }
    }

    @objc private func didEnterBackground() {
        isInBackground = true
        stopTimer()
        cancelAnimation()
    }

    @objc private func didBecomeActive() {
        isInBackground = false
        if itemCount > 0 && !collectionView.isDragging && !collectionView.isDecelerating {
            settle()
        } else {
            scheduleAutoScroll()
        }
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        physicalCount
    }

    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        activeDequeuingPath = indexPath
        defer { activeDequeuingPath = nil }
        guard let dataSource = dataSource else { return UICollectionViewCell() }
        return dataSource.carouselView(self, cellForItemAt: logicalIndex(for: indexPath.item))
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.carouselView?(self, didSelectItemAt: logicalIndex(for: indexPath.item))
    }

    public func collectionView(_ collectionView: UICollectionView,
                               willDisplay cell: UICollectionViewCell,
                               forItemAt indexPath: IndexPath) {
        let progress = carouselLayout.progress(for: indexPath.item,
                                               contentOffset: collectionView.contentOffset.x)
        delegate?.carouselView?(self, didUpdate: cell,
                                at: logicalIndex(for: indexPath.item), progress: progress)
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isReloading, itemCount > 0, !isRecentering else { return }
        recenterIfNeeded()
        reportVisibleProgress()
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        stopTimer()
        cancelAnimation()
    }

    public func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                          withVelocity velocity: CGPoint,
                                          targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard itemCount > 0 else { return }
        let physical = carouselLayout.nearestPhysicalIndex(at: targetContentOffset.pointee.x,
                                                           count: physicalCount)
        targetContentOffset.pointee.x = boundedOffset(carouselLayout.targetOffset(for: physical))
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { settle() }
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        settle()
    }
}
