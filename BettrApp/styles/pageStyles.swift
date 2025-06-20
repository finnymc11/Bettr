//
//  pageStyles.swift
//  BettrApp
//
//  Created by CJ Balmaceda on 6/20/25.
//

import Foundation
import SwiftUI

struct customStyle: ViewModifier{
    func body(content: Content) -> some View{
        content
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
    }
}

struct buttonStyle: ViewModifier{
    func body(content: Content) -> some View{
        content
//            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
//            .padding(.horizontal)
                       .background(Color.white)
                       .foregroundColor(.black)
                       .clipShape(Capsule())
        
    }
}



extension View{
    func cStyle1() -> some View{
        self.modifier(customStyle())
    }
    func uniformButt() -> some View{
        self.modifier(BettrApp.buttonStyle())
    }
    
}
