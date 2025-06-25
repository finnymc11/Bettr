//
//  Stats.swift
//  
//
//  Created by CJ Balmaceda on 6/20/25.
//

import SwiftUI

struct statsView: View{
    var body: some View{
        NavigationStack {
            VStack(spacing: 0) {
                VStack{
                    Text("🧠")
                        .font(.system(size: 96))
                        .padding(.bottom, -15)
                    Text("Behavioral Analysis")
                        .foregroundColor(.white)
                        .font(.system(size: 40))
                        .padding(.bottom, 400)
                }.cStyle1()
            }.cStyle1()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Text("Stats")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: InfoView()) {
                        Image(systemName: "info")
                            .font(.system(size: 20))
                            //.foregroundColor(.white)
                    }
                }
            }
        }
    }
}

#Preview {
    statsView()
}
