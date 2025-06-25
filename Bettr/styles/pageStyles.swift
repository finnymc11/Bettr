//
//  pageStyles.swift
//  BettrApp
//
//  Created by CJ Balmaceda on 6/20/25.
//

import Foundation
import SwiftUI


//style for tabview
struct cStyle1: ViewModifier{
    func body(content: Content) -> some View{
        content
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
    }
}

//capsule button
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

//Text styles
struct textStyle: ViewModifier{
    func body(content: Content) -> some View{
        content
            .foregroundColor(.white)
            .font(.system(size: 60,weight: .heavy,design: .default))
            .tracking(2.5)
           
    }
    
}

struct textStyleRegular: ViewModifier{
    func body(content: Content) -> some View{
        content
            .foregroundColor(.white)
            .font(.system(size: 40,weight: .thin, design: .default))
            .tracking(2.5)
           
    }
}


extension View{
    func cStyle1() -> some View{
        self.modifier(Bettr.cStyle1())
    }
    func uniformButt() -> some View{
        self.modifier(Bettr.buttonStyle())
    }
    func textStyleBig() -> some View{
        self.modifier(textStyle())
    }
    func textStyleReg()->some View{
        self.modifier(textStyleRegular())
    }
    
}
