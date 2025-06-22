//
//  SplashView.swift
//  BettrApp
//
//  Created by Finbar McCarron on 6/20/25.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                Text("Welcome to My App")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(2)
                    .padding()
            }
        }
    }
}
