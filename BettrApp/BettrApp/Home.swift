//
//  Home.swift
//  BettrApp
//
//  Created by Finbar McCarron on 6/17/25.
//

import SwiftUI

struct Home: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hey, finbar!")
        }
        .padding()
    }
}

#Preview {
    Home()
}
