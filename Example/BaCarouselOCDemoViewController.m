#import "BaCarouselOCDemoViewController.h"
#import <BaPagerView/BaPagerView-Swift.h>

@interface BaCarouselOCDemoItem : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *symbol;
@property (nonatomic, copy) NSString *badge;
@property (nonatomic, strong) UIColor *color;

- (instancetype)initWithTitle:(NSString *)title
                    subtitle:(NSString *)subtitle
                      symbol:(NSString *)symbol
                       badge:(NSString *)badge
                       color:(UIColor *)color;

@end

@implementation BaCarouselOCDemoItem

- (instancetype)initWithTitle:(NSString *)title
                    subtitle:(NSString *)subtitle
                      symbol:(NSString *)symbol
                       badge:(NSString *)badge
                       color:(UIColor *)color {
    self = [super init];
    if (self) {
        _title = [title copy];
        _subtitle = [subtitle copy];
        _symbol = [symbol copy];
        _badge = [badge copy];
        _color = color;
    }
    return self;
}

@end

@interface BaCarouselOCDemoCell : UICollectionViewCell

- (void)configureWithItem:(BaCarouselOCDemoItem *)item number:(NSInteger)number;
- (void)updateWithProgress:(CGFloat)progress;

@end

@interface BaCarouselOCDemoCell ()

@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIImageView *symbolView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UILabel *badgeLabel;

@end

@implementation BaCarouselOCDemoCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.shadowColor = UIColor.blackColor.CGColor;
        self.layer.shadowOpacity = 0.22;
        self.layer.shadowRadius = 14;
        self.layer.shadowOffset = CGSizeMake(0, 8);
        self.layer.masksToBounds = NO;

        _cardView = [[UIView alloc] init];
        _cardView.layer.cornerRadius = 18;
        _cardView.layer.masksToBounds = YES;
        _cardView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_cardView];

        _symbolView = [[UIImageView alloc] init];
        _symbolView.contentMode = UIViewContentModeScaleAspectFit;
        _symbolView.tintColor = UIColor.whiteColor;
        _symbolView.translatesAutoresizingMaskIntoConstraints = NO;
        [_cardView addSubview:_symbolView];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont boldSystemFontOfSize:25];
        _titleLabel.textColor = UIColor.whiteColor;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_cardView addSubview:_titleLabel];

        _subtitleLabel = [[UILabel alloc] init];
        _subtitleLabel.font = [UIFont systemFontOfSize:14];
        _subtitleLabel.textColor = [UIColor.whiteColor colorWithAlphaComponent:0.88];
        _subtitleLabel.textAlignment = NSTextAlignmentCenter;
        _subtitleLabel.numberOfLines = 2;
        _subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_cardView addSubview:_subtitleLabel];

        _badgeLabel = [[UILabel alloc] init];
        _badgeLabel.font = [UIFont boldSystemFontOfSize:12];
        _badgeLabel.textColor = UIColor.whiteColor;
        _badgeLabel.textAlignment = NSTextAlignmentCenter;
        _badgeLabel.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.22];
        _badgeLabel.layer.cornerRadius = 11;
        _badgeLabel.layer.masksToBounds = YES;
        _badgeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_cardView addSubview:_badgeLabel];

        [NSLayoutConstraint activateConstraints:@[
            [_cardView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
            [_cardView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
            [_cardView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
            [_cardView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
            [_symbolView.centerXAnchor constraintEqualToAnchor:_cardView.centerXAnchor],
            [_symbolView.topAnchor constraintEqualToAnchor:_cardView.topAnchor constant:48],
            [_symbolView.widthAnchor constraintEqualToConstant:72],
            [_symbolView.heightAnchor constraintEqualToConstant:72],
            [_titleLabel.topAnchor constraintEqualToAnchor:_symbolView.bottomAnchor constant:28],
            [_titleLabel.leadingAnchor constraintEqualToAnchor:_cardView.leadingAnchor constant:12],
            [_titleLabel.trailingAnchor constraintEqualToAnchor:_cardView.trailingAnchor constant:-12],
            [_subtitleLabel.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:12],
            [_subtitleLabel.leadingAnchor constraintEqualToAnchor:_cardView.leadingAnchor constant:15],
            [_subtitleLabel.trailingAnchor constraintEqualToAnchor:_cardView.trailingAnchor constant:-15],
            [_badgeLabel.topAnchor constraintEqualToAnchor:_cardView.topAnchor constant:14],
            [_badgeLabel.trailingAnchor constraintEqualToAnchor:_cardView.trailingAnchor constant:-14],
            [_badgeLabel.widthAnchor constraintGreaterThanOrEqualToConstant:58],
            [_badgeLabel.heightAnchor constraintEqualToConstant:22]
        ]];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:18].CGPath;
}

- (void)configureWithItem:(BaCarouselOCDemoItem *)item number:(NSInteger)number {
    self.cardView.backgroundColor = item.color;
    self.symbolView.image = [UIImage systemImageNamed:item.symbol];
    self.titleLabel.text = item.title;
    self.subtitleLabel.text = item.subtitle;
    self.badgeLabel.text = [NSString stringWithFormat:@"  %@ · %ld  ", item.badge, (long)number];
    self.badgeLabel.alpha = 1;
}

- (void)updateWithProgress:(CGFloat)progress {
    self.badgeLabel.alpha = 0.55 + 0.45 * progress;
}

@end

@interface BaCarouselOCDemoViewController () <BaCarouselViewDataSource, BaCarouselViewDelegate>

@property (nonatomic, strong) BaCarouselView *carouselView;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UISegmentedControl *alignmentControl;
@property (nonatomic, strong) UISegmentedControl *directionControl;
@property (nonatomic, strong) UISwitch *infiniteSwitch;
@property (nonatomic, strong) UISwitch *autoSwitch;
@property (nonatomic, strong) UISlider *intervalSlider;
@property (nonatomic, strong) UISlider *durationSlider;
@property (nonatomic, strong) UILabel *intervalLabel;
@property (nonatomic, strong) UILabel *durationLabel;
@property (nonatomic, strong) UIButton *reloadButton;
@property (nonatomic, copy) NSArray<BaCarouselOCDemoItem *> *sampleItems;
@property (nonatomic, copy) NSArray<BaCarouselOCDemoItem *> *items;
@property (nonatomic, assign) BOOL showsTwoItems;

@end

@implementation BaCarouselOCDemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"轮播组件测试";
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.carouselView = [[BaCarouselView alloc] initWithFrame:CGRectZero];
    self.statusLabel = [[UILabel alloc] init];
    self.alignmentControl = [[UISegmentedControl alloc] initWithItems:@[@"左侧", @"居中", @"右侧"]];
    self.directionControl = [[UISegmentedControl alloc] initWithItems:@[@"向左", @"向右"]];
    self.infiniteSwitch = [[UISwitch alloc] init];
    self.autoSwitch = [[UISwitch alloc] init];
    self.intervalSlider = [[UISlider alloc] init];
    self.durationSlider = [[UISlider alloc] init];
    self.intervalLabel = [[UILabel alloc] init];
    self.durationLabel = [[UILabel alloc] init];
    self.reloadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.items = @[];
    self.sampleItems = @[
        [[BaCarouselOCDemoItem alloc] initWithTitle:@"城市新闻" subtitle:@"拖动时观察卡片的连续缩放" symbol:@"newspaper.fill" badge:@"新闻" color:UIColor.systemBlueColor],
        [[BaCarouselOCDemoItem alloc] initWithTitle:@"精彩视频" subtitle:@"松手后自动吸附到设定位置" symbol:@"play.rectangle.fill" badge:@"视频" color:UIColor.systemIndigoColor],
        [[BaCarouselOCDemoItem alloc] initWithTitle:@"声音现场" subtitle:@"测试阴影、标题和标签随 Cell 复用" symbol:@"headphones" badge:@"音频" color:UIColor.systemTealColor],
        [[BaCarouselOCDemoItem alloc] initWithTitle:@"城市专题" subtitle:@"切换左右方向与无限循环" symbol:@"star.fill" badge:@"专题" color:UIColor.systemOrangeColor],
        [[BaCarouselOCDemoItem alloc] initWithTitle:@"图集故事" subtitle:@"改变自动轮播间隔和动画时间" symbol:@"photo.fill" badge:@"图集" color:UIColor.systemPinkColor]
    ];
    [self buildInterface];

    self.alignmentControl.selectedSegmentIndex = 1;
    self.directionControl.selectedSegmentIndex = 0;
    self.infiniteSwitch.on = YES;
    self.autoSwitch.on = YES;
    self.intervalSlider.minimumValue = 1;
    self.intervalSlider.maximumValue = 5;
    self.intervalSlider.value = 2.5;
    self.durationSlider.minimumValue = 0.15;
    self.durationSlider.maximumValue = 1.5;
    self.durationSlider.value = 0.55;
    [self updateSliderLabels];

    self.carouselView.dataSource = self;
    self.carouselView.delegate = self;
    [self.carouselView registerClass:BaCarouselOCDemoCell.class forCellWithReuseIdentifier:@"demo"];
    [self applyConfiguration];
    [self updateStatus:@"等待示例数据…"];

    // Simulate a response: the page owns the array and reloads the carousel on the main queue.
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf loadItemsWithTwoItems:NO];
    });
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.carouselView.isAutoScrollPaused = NO;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.carouselView.isAutoScrollPaused = YES;
}

- (void)buildInterface {
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.alwaysBounceVertical = YES;
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:scrollView];

    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 16;
    stack.layoutMarginsRelativeArrangement = YES;
    stack.layoutMargins = UIEdgeInsetsMake(16, 16, 24, 16);
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [scrollView addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [stack.topAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor],
        [stack.bottomAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor],
        [stack.leadingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.trailingAnchor],
        [stack.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor]
    ]];

    UILabel *introduction = [[UILabel alloc] init];
    introduction.text = @"滑动卡片观察缩放；下方可以切换吸附、方向和计时。";
    introduction.font = [UIFont systemFontOfSize:14];
    introduction.textColor = UIColor.secondaryLabelColor;
    introduction.numberOfLines = 0;
    [stack addArrangedSubview:introduction];

    [stack addArrangedSubview:self.carouselView];
    [self.carouselView.heightAnchor constraintEqualToConstant:340].active = YES;

    self.statusLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    self.statusLabel.textColor = UIColor.labelColor;
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.numberOfLines = 2;
    [stack addArrangedSubview:self.statusLabel];

    [stack addArrangedSubview:[self sectionLabel:@"吸附位置"]];
    [stack addArrangedSubview:self.alignmentControl];
    [self.alignmentControl addTarget:self action:@selector(controlChanged) forControlEvents:UIControlEventValueChanged];

    [stack addArrangedSubview:[self sectionLabel:@"自动轮播方向"]];
    [stack addArrangedSubview:self.directionControl];
    [self.directionControl addTarget:self action:@selector(controlChanged) forControlEvents:UIControlEventValueChanged];

    [stack addArrangedSubview:[self switchRow:@"无限循环" control:self.infiniteSwitch]];
    [stack addArrangedSubview:[self switchRow:@"自动轮播" control:self.autoSwitch]];
    [self.infiniteSwitch addTarget:self action:@selector(controlChanged) forControlEvents:UIControlEventValueChanged];
    [self.autoSwitch addTarget:self action:@selector(controlChanged) forControlEvents:UIControlEventValueChanged];

    self.intervalLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [stack addArrangedSubview:self.intervalLabel];
    [stack addArrangedSubview:self.intervalSlider];
    self.durationLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [stack addArrangedSubview:self.durationLabel];
    [stack addArrangedSubview:self.durationSlider];
    for (UISlider *slider in @[self.intervalSlider, self.durationSlider]) {
        [slider addTarget:self action:@selector(sliderValueChanged) forControlEvents:UIControlEventValueChanged];
        [slider addTarget:self action:@selector(controlChanged) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    }

    UIStackView *navigationButtons = [[UIStackView alloc] init];
    navigationButtons.axis = UILayoutConstraintAxisHorizontal;
    navigationButtons.distribution = UIStackViewDistributionFillEqually;
    navigationButtons.spacing = 12;
    UIButton *previousButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [previousButton setTitle:@"上一项" forState:UIControlStateNormal];
    [previousButton addTarget:self action:@selector(showPrevious) forControlEvents:UIControlEventTouchUpInside];
    UIButton *nextButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [nextButton setTitle:@"下一项" forState:UIControlStateNormal];
    [nextButton addTarget:self action:@selector(showNext) forControlEvents:UIControlEventTouchUpInside];
    [navigationButtons addArrangedSubview:previousButton];
    [navigationButtons addArrangedSubview:nextButton];
    [stack addArrangedSubview:navigationButtons];

    [self.reloadButton setTitle:@"切换为 2 条数据" forState:UIControlStateNormal];
    [self.reloadButton addTarget:self action:@selector(toggleData) forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:self.reloadButton];
}

- (UILabel *)sectionLabel:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    label.textColor = UIColor.labelColor;
    return label;
}

- (UIView *)switchRow:(NSString *)title control:(UISwitch *)control {
    UIStackView *row = [[UIStackView alloc] init];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.alignment = UIStackViewAlignmentCenter;
    [row addArrangedSubview:[self sectionLabel:title]];
    [row addArrangedSubview:control];
    return row;
}

- (void)updateSliderLabels {
    self.intervalLabel.text = [NSString stringWithFormat:@"轮播间隔：%.1f 秒", self.intervalSlider.value];
    self.durationLabel.text = [NSString stringWithFormat:@"动画时间：%.2f 秒", self.durationSlider.value];
}

- (void)applyConfiguration {
    BaCarouselConfiguration *configuration = [[BaCarouselConfiguration alloc] init];
    configuration.itemSize = CGSizeMake(220, 290);
    configuration.itemSpacing = 20;
    configuration.alignment = (BaCarouselAlignment)self.alignmentControl.selectedSegmentIndex;
    configuration.alignmentOffset = configuration.alignment == BaCarouselAlignmentCenter ? 0 : 20;
    configuration.minimumScale = 0.78;
    configuration.maximumScale = 1;
    configuration.isInfiniteLoop = self.infiniteSwitch.on;
    configuration.autoDirection = self.directionControl.selectedSegmentIndex == 0 ? BaCarouselAutoDirectionLeft : BaCarouselAutoDirectionRight;
    configuration.autoScrollInterval = self.autoSwitch.on ? self.intervalSlider.value : 0;
    configuration.scrollAnimationDuration = self.durationSlider.value;
    self.carouselView.configuration = configuration;
    [self updateStatus:nil];
}

- (void)loadItemsWithTwoItems:(BOOL)twoItems {
    self.showsTwoItems = twoItems;
    self.items = twoItems ? [self.sampleItems subarrayWithRange:NSMakeRange(0, 2)] : self.sampleItems;
    [self.carouselView reloadData];
    [self.reloadButton setTitle:twoItems ? @"恢复 5 条数据" : @"切换为 2 条数据" forState:UIControlStateNormal];
    [self updateStatus:nil];
}

- (void)updateStatus:(NSString *)message {
    if (message) {
        self.statusLabel.text = message;
    } else if (self.items.count == 0) {
        self.statusLabel.text = @"当前没有数据";
    } else {
        self.statusLabel.text = [NSString stringWithFormat:@"当前第 %ld / %ld 项 · 点击卡片可查看反馈", (long)self.carouselView.currentIndex + 1, (long)self.items.count];
    }
}

- (void)controlChanged {
    [self applyConfiguration];
}

- (void)sliderValueChanged {
    [self updateSliderLabels];
}

- (void)toggleData {
    [self loadItemsWithTwoItems:!self.showsTwoItems];
}

- (void)showPrevious {
    if (self.items.count == 0) { return; }
    NSInteger index = self.carouselView.currentIndex - 1;
    if (index >= 0) {
        [self.carouselView scrollToItemAtIndex:index animated:YES];
    } else if (self.infiniteSwitch.on) {
        [self.carouselView scrollToItemAtIndex:self.items.count - 1 animated:YES];
    }
}

- (void)showNext {
    if (self.items.count == 0) { return; }
    NSInteger index = self.carouselView.currentIndex + 1;
    if (index < self.items.count) {
        [self.carouselView scrollToItemAtIndex:index animated:YES];
    } else if (self.infiniteSwitch.on) {
        [self.carouselView scrollToItemAtIndex:0 animated:YES];
    }
}

#pragma mark - BaCarouselViewDataSource

- (NSInteger)numberOfItemsInCarouselView:(BaCarouselView *)carouselView {
    return self.items.count;
}

- (UICollectionViewCell *)carouselView:(BaCarouselView *)carouselView cellForItemAtIndex:(NSInteger)index {
    BaCarouselOCDemoCell *cell = (BaCarouselOCDemoCell *)[carouselView dequeueReusableCellWithReuseIdentifier:@"demo" forIndex:index];
    [cell configureWithItem:self.items[index] number:index + 1];
    return cell;
}

#pragma mark - BaCarouselViewDelegate

- (void)carouselView:(BaCarouselView *)carouselView didSelectItemAtIndex:(NSInteger)index {
    [self updateStatus:[NSString stringWithFormat:@"点击了第 %ld 项：%@", (long)index + 1, self.items[index].title]];
}

- (void)carouselView:(BaCarouselView *)carouselView didSettleAtIndex:(NSInteger)index {
    [self updateStatus:nil];
}

- (void)carouselView:(BaCarouselView *)carouselView didUpdateCell:(UICollectionViewCell *)cell atIndex:(NSInteger)index progress:(CGFloat)progress {
    [(BaCarouselOCDemoCell *)cell updateWithProgress:progress];
}

@end
