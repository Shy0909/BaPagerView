import UIKit
import BaPagerView

private struct BaCarouselDemoItem {
    let title: String
    let subtitle: String
    let symbol: String
    let badge: String
    let color: UIColor
}

private final class BaCarouselDemoCell: UICollectionViewCell {
    private let cardView = UIView()
    private let symbolView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let badgeLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.22
        layer.shadowRadius = 14
        layer.shadowOffset = CGSize(width: 0, height: 8)
        layer.masksToBounds = false

        cardView.layer.cornerRadius = 18
        cardView.layer.masksToBounds = true
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)

        symbolView.contentMode = .scaleAspectFit
        symbolView.tintColor = .white
        symbolView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(symbolView)

        titleLabel.font = .boldSystemFont(ofSize: 25)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)

        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.88)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 2
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(subtitleLabel)

        badgeLabel.font = .boldSystemFont(ofSize: 12)
        badgeLabel.textColor = .white
        badgeLabel.textAlignment = .center
        badgeLabel.backgroundColor = UIColor.black.withAlphaComponent(0.22)
        badgeLabel.layer.cornerRadius = 11
        badgeLabel.layer.masksToBounds = true
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(badgeLabel)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            symbolView.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            symbolView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 48),
            symbolView.widthAnchor.constraint(equalToConstant: 72),
            symbolView.heightAnchor.constraint(equalToConstant: 72),
            titleLabel.topAnchor.constraint(equalTo: symbolView.bottomAnchor, constant: 28),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            subtitleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 15),
            subtitleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -15),
            badgeLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            badgeLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 58),
            badgeLabel.heightAnchor.constraint(equalToConstant: 22)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 18).cgPath
    }

    func configure(with item: BaCarouselDemoItem, number: Int) {
        cardView.backgroundColor = item.color
        symbolView.image = UIImage(systemName: item.symbol)
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        badgeLabel.text = "  \(item.badge) · \(number)  "
        badgeLabel.alpha = 1
    }

    func update(progress: CGFloat) {
        badgeLabel.alpha = 0.55 + 0.45 * progress
    }
}

/// DEBUG entry: double tap the app icon on the news home page.
@objc(BaCarouselDemoViewController)
public final class BaCarouselDemoViewController: UIViewController, BaCarouselViewDataSource, BaCarouselViewDelegate {
    private let carouselView = BaCarouselView()
    private let statusLabel = UILabel()
    private let alignmentControl = UISegmentedControl(items: ["左侧", "居中", "右侧"])
    private let directionControl = UISegmentedControl(items: ["向左", "向右"])
    private let infiniteSwitch = UISwitch()
    private let autoSwitch = UISwitch()
    private let intervalSlider = UISlider()
    private let durationSlider = UISlider()
    private let intervalLabel = UILabel()
    private let durationLabel = UILabel()
    private let reloadButton = UIButton(type: .system)

    private var items: [BaCarouselDemoItem] = []
    private var showsTwoItems = false

    private let sampleItems: [BaCarouselDemoItem] = [
        BaCarouselDemoItem(title: "城市新闻", subtitle: "拖动时观察卡片的连续缩放", symbol: "newspaper.fill", badge: "新闻", color: .systemBlue),
        BaCarouselDemoItem(title: "精彩视频", subtitle: "松手后自动吸附到设定位置", symbol: "play.rectangle.fill", badge: "视频", color: .systemIndigo),
        BaCarouselDemoItem(title: "声音现场", subtitle: "测试阴影、标题和标签随 Cell 复用", symbol: "headphones", badge: "音频", color: .systemTeal),
        BaCarouselDemoItem(title: "城市专题", subtitle: "切换左右方向与无限循环", symbol: "star.fill", badge: "专题", color: .systemOrange),
        BaCarouselDemoItem(title: "图集故事", subtitle: "改变自动轮播间隔和动画时间", symbol: "photo.fill", badge: "图集", color: .systemPink)
    ]

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "轮播组件测试"
        view.backgroundColor = .systemGroupedBackground
        buildInterface()

        alignmentControl.selectedSegmentIndex = 1
        directionControl.selectedSegmentIndex = 0
        infiniteSwitch.isOn = true
        autoSwitch.isOn = true
        intervalSlider.minimumValue = 1
        intervalSlider.maximumValue = 5
        intervalSlider.value = 2.5
        durationSlider.minimumValue = 0.15
        durationSlider.maximumValue = 1.5
        durationSlider.value = 0.55
        updateSliderLabels()

        carouselView.dataSource = self
        carouselView.delegate = self
        carouselView.register(BaCarouselDemoCell.self, forCellWithReuseIdentifier: "demo")
        applyConfiguration()
        updateStatus("等待示例数据…")

        // Simulates an asynchronous response: the page retains data, then reloads the carousel.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.loadItems(twoItems: false)
        }
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        carouselView.isAutoScrollPaused = false
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        carouselView.isAutoScrollPaused = true
    }

    private func buildInterface() {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 24, right: 16)
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        let introduction = UILabel()
        introduction.text = "滑动卡片观察缩放；下方可以切换吸附、方向和计时。"
        introduction.font = .systemFont(ofSize: 14)
        introduction.textColor = .secondaryLabel
        introduction.numberOfLines = 0
        stack.addArrangedSubview(introduction)

        stack.addArrangedSubview(carouselView)
        carouselView.heightAnchor.constraint(equalToConstant: 340).isActive = true

        statusLabel.font = .systemFont(ofSize: 14, weight: .medium)
        statusLabel.textColor = .label
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 2
        stack.addArrangedSubview(statusLabel)

        stack.addArrangedSubview(sectionLabel("吸附位置"))
        stack.addArrangedSubview(alignmentControl)
        alignmentControl.addTarget(self, action: #selector(controlChanged), for: .valueChanged)

        stack.addArrangedSubview(sectionLabel("自动轮播方向"))
        stack.addArrangedSubview(directionControl)
        directionControl.addTarget(self, action: #selector(controlChanged), for: .valueChanged)

        stack.addArrangedSubview(switchRow("无限循环", control: infiniteSwitch))
        stack.addArrangedSubview(switchRow("自动轮播", control: autoSwitch))
        infiniteSwitch.addTarget(self, action: #selector(controlChanged), for: .valueChanged)
        autoSwitch.addTarget(self, action: #selector(controlChanged), for: .valueChanged)

        intervalLabel.font = .systemFont(ofSize: 14, weight: .medium)
        stack.addArrangedSubview(intervalLabel)
        stack.addArrangedSubview(intervalSlider)
        durationLabel.font = .systemFont(ofSize: 14, weight: .medium)
        stack.addArrangedSubview(durationLabel)
        stack.addArrangedSubview(durationSlider)
        for slider in [intervalSlider, durationSlider] {
            slider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
            slider.addTarget(self, action: #selector(controlChanged), for: [.touchUpInside, .touchUpOutside])
        }

        let navigationButtons = UIStackView()
        navigationButtons.axis = .horizontal
        navigationButtons.distribution = .fillEqually
        navigationButtons.spacing = 12
        let previousButton = UIButton(type: .system)
        previousButton.setTitle("上一项", for: .normal)
        previousButton.addTarget(self, action: #selector(showPrevious), for: .touchUpInside)
        let nextButton = UIButton(type: .system)
        nextButton.setTitle("下一项", for: .normal)
        nextButton.addTarget(self, action: #selector(showNext), for: .touchUpInside)
        navigationButtons.addArrangedSubview(previousButton)
        navigationButtons.addArrangedSubview(nextButton)
        stack.addArrangedSubview(navigationButtons)

        reloadButton.setTitle("切换为 2 条数据", for: .normal)
        reloadButton.addTarget(self, action: #selector(toggleData), for: .touchUpInside)
        stack.addArrangedSubview(reloadButton)
    }

    private func sectionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .label
        return label
    }

    private func switchRow(_ title: String, control: UISwitch) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        let label = sectionLabel(title)
        row.addArrangedSubview(label)
        row.addArrangedSubview(control)
        return row
    }

    private func updateSliderLabels() {
        intervalLabel.text = String(format: "轮播间隔：%.1f 秒", intervalSlider.value)
        durationLabel.text = String(format: "动画时间：%.2f 秒", durationSlider.value)
    }

    private func applyConfiguration() {
        let configuration = BaCarouselConfiguration()
        configuration.itemSize = CGSize(width: 220, height: 290)
        configuration.itemSpacing = 20
        configuration.alignment = BaCarouselAlignment(rawValue: alignmentControl.selectedSegmentIndex) ?? .center
        configuration.alignmentOffset = configuration.alignment == .center ? 0 : 20
        configuration.minimumScale = 0.78
        configuration.maximumScale = 1
        configuration.isInfiniteLoop = infiniteSwitch.isOn
        configuration.autoDirection = directionControl.selectedSegmentIndex == 0 ? .left : .right
        configuration.autoScrollInterval = autoSwitch.isOn ? TimeInterval(intervalSlider.value) : 0
        configuration.scrollAnimationDuration = TimeInterval(durationSlider.value)
        carouselView.configuration = configuration
        updateStatus()
    }

    private func loadItems(twoItems: Bool) {
        showsTwoItems = twoItems
        items = twoItems ? Array(sampleItems.prefix(2)) : sampleItems
        carouselView.reloadData()
        reloadButton.setTitle(twoItems ? "恢复 5 条数据" : "切换为 2 条数据", for: .normal)
        updateStatus()
    }

    private func updateStatus(_ message: String? = nil) {
        if let message = message {
            statusLabel.text = message
        } else if items.isEmpty {
            statusLabel.text = "当前没有数据"
        } else {
            statusLabel.text = "当前第 \(carouselView.currentIndex + 1) / \(items.count) 项 · 点击卡片可查看反馈"
        }
    }

    @objc private func controlChanged() {
        applyConfiguration()
    }

    @objc private func sliderValueChanged() {
        updateSliderLabels()
    }

    @objc private func toggleData() {
        loadItems(twoItems: !showsTwoItems)
    }

    @objc private func showPrevious() {
        guard !items.isEmpty else { return }
        let index = carouselView.currentIndex - 1
        if index >= 0 {
            carouselView.scrollToItem(at: index, animated: true)
        } else if infiniteSwitch.isOn {
            carouselView.scrollToItem(at: items.count - 1, animated: true)
        }
    }

    @objc private func showNext() {
        guard !items.isEmpty else { return }
        let index = carouselView.currentIndex + 1
        if index < items.count {
            carouselView.scrollToItem(at: index, animated: true)
        } else if infiniteSwitch.isOn {
            carouselView.scrollToItem(at: 0, animated: true)
        }
    }

    public func numberOfItems(in carouselView: BaCarouselView) -> Int {
        items.count
    }

    public func carouselView(_ carouselView: BaCarouselView, cellForItemAt index: Int) -> UICollectionViewCell {
        let cell = carouselView.dequeueReusableCell(withReuseIdentifier: "demo", for: index) as! BaCarouselDemoCell
        cell.configure(with: items[index], number: index + 1)
        return cell
    }

    public func carouselView(_ carouselView: BaCarouselView, didSelectItemAt index: Int) {
        updateStatus("点击了第 \(index + 1) 项：\(items[index].title)")
    }

    public func carouselView(_ carouselView: BaCarouselView, didSettleAt index: Int) {
        updateStatus()
    }

    public func carouselView(_ carouselView: BaCarouselView,
                             didUpdate cell: UICollectionViewCell,
                             at index: Int,
                             progress: CGFloat) {
        (cell as? BaCarouselDemoCell)?.update(progress: progress)
    }
}
