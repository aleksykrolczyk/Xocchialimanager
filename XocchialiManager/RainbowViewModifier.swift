//
//  RainbowViewModifier.swift
//  XocchialiManager
//
//  Created by Aleksy Krolczyk on 07/11/2022.:
//

import SwiftUI

struct Rainbow: ViewModifier {
    let hueColors = stride(from: 0, to: 1, by: 0.01).map {
        Color(hue: $0, saturation: 1, brightness: 1)
    }

    @State var isOn = false
    let duration: Double = 4
    var animaion: Animation {
        Animation
            .linear(duration: duration)
            .repeatForever(autoreverses: false)
    }

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geometry in
                    let width = geometry.size.width
                    LinearGradient(gradient: Gradient(colors: hueColors + hueColors), startPoint: .leading, endPoint: .trailing)
                        .frame(width: 2 * width)
                        .offset(x: isOn ? -width : 0)
                }
            }
            .onAppear {
                withAnimation(self.animaion) {
                    isOn = true
                }
            }
            .mask(content)
    }
}

extension View {
    func rainbowAnimation() -> some View {
        self.modifier(Rainbow())
    }
}
