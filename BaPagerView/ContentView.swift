//
//  ContentView.swift
//  BaPagerView
//
//  Created by Shy0909 on 2026/9/24.
//

import SwiftUI
import UIKit

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("BaPagerView")
                    .font(.largeTitle)
                NavigationLink("Swift 示例", destination: SwiftCarouselDemo()
                    .navigationBarTitle("轮播组件测试", displayMode: .inline))
                NavigationLink("Objective-C 示例", destination: ObjectiveCCarouselDemo()
                    .navigationBarTitle("轮播组件测试", displayMode: .inline))
            }
            .navigationBarTitle("轮播组件", displayMode: .inline)
        }
    }
}

private struct SwiftCarouselDemo: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> BaCarouselDemoViewController {
        BaCarouselDemoViewController()
    }

    func updateUIViewController(_ controller: BaCarouselDemoViewController, context: Context) {}
}

private struct ObjectiveCCarouselDemo: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> BaCarouselOCDemoViewController {
        BaCarouselOCDemoViewController()
    }

    func updateUIViewController(_ controller: BaCarouselOCDemoViewController, context: Context) {}
}

#Preview {
    ContentView()
}
