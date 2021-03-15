//
//  Spinning.swift
//  EmojiArt
//
//  Created by Vicente Montoya on 9/4/20.
//  Copyright © 2020 Vicente Montoya. All rights reserved.
//

import Foundation
import SwiftUI

struct Spinning: ViewModifier{
    @State var isVisible = false
    
    func body(content: Content)-> some View{
        content
            .rotationEffect(Angle(degrees: isVisible ? 360 : 0 ))
            .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false))
            .onAppear{ self.isVisible = true}
    }
}

extension View{
    func spinning() -> some View{
        self.modifier(Spinning())
    }
}
