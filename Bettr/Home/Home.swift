//
//  Home.swift
//  BettrApp
//
//  Created by Finbar McCarron on 6/17/25.


import SwiftUI

struct Home: View {
    @State private var selection: Int = 0
    var body: some View {
        TabView(selection: $selection){
            Tab("Stats", systemImage: "hourglass", value: 0){
                statsView()
            }
            Tab("Home", systemImage: "house.fill", value: 1){
                homeView()
            }
            Tab("Leaderboard", systemImage: "person.3.fill", value: 2){
                leaderView()
            }
        }.tint(.white)
    }
}


struct customStyle: ViewModifier{
    func body(content: Content) -> some View{
        content
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
    }
}





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




#Preview {
    Home()
}
