# BaPagerView

BaPagerView 是一个 UIKit 横向轮播组件，支持 Swift 和 Objective-C，最低支持 iOS 13。可以设置卡片尺寸与间距、对齐方式、缩放效果、自动滚动和无限循环。

## 安装

在 App 的 `Podfile` 中添加：

```ruby
platform :ios, '13.0'
use_frameworks!

target 'YourApp' do
  pod 'BaPagerView', :git => 'https://github.com/Shy0909/BaPagerView.git', :tag => 'v0.1.0'
end
```

运行 `pod install`，并使用生成的 `.xcworkspace` 打开 App。

## Swift 使用

```swift
import BaPagerView

let carouselView = BaCarouselView()
let configuration = BaCarouselConfiguration()
configuration.itemSpacing = 12
configuration.isInfiniteLoop = true
configuration.autoScrollInterval = 3
carouselView.configuration = configuration
```

设置 `dataSource`，注册 `UICollectionViewCell` 子类，再调用 `reloadData()`。完整用法见 [Swift 示例](Example/BaCarouselDemoViewController.swift)。

## Objective-C 使用

```objc
#import <BaPagerView/BaPagerView-Swift.h>

BaCarouselView *carouselView = [[BaCarouselView alloc] initWithFrame:CGRectZero];
BaCarouselConfiguration *configuration = [[BaCarouselConfiguration alloc] init];
configuration.isInfiniteLoop = YES;
carouselView.configuration = configuration;
```

实现 `BaCarouselViewDataSource` 的 `numberOfItemsInCarouselView:` 和 `carouselView:cellForItemAtIndex:`，然后调用 `reloadData`。完整用法见 [Objective-C 示例](Example/BaCarouselOCDemoViewController.m)。

## 许可

见 [MIT LICENSE](LICENSE)。
