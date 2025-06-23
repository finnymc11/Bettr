//
//  pageStyles.swift
//  BettrApp
//
//  Created by CJ Balmaceda on 6/20/25.
//

import SwiftUI

struct homeView: View{
    var body: some View{
        VStack{
            Text("home").foregroundStyle(.white)
        }.cStyle1()
    }
}

struct statsView: View{
    var body: some View{
        VStack{
            Text("bruh").foregroundStyle(.white)
        }.cStyle1()
    }
}
struct leaderView: View{
    var body: some View{
        VStack{
            Text("bruh").foregroundStyle(.white)
        }.cStyle1()
    }
}

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
        self.modifier(Bettr.buttonStyle())
    }
    
}
