//
//  signUp.swift
//  BettrApp
//
//  Created by CJ Balmaceda on 6/20/25.
//

import Foundation
import SwiftUI



struct signUp: View{
    var body: some View{
        VStack{
            HStack{
                Text("Are you ready to be better?")
                    .foregroundColor(.white)
                    .padding(.trailing)
//                    .font(.largeTitle)
                    .font(.system(size: 40, weight: .semibold, design: .default))
                    
                Spacer()
            }.padding(.bottom, 100)
           
            Button(action: {
                print("signup butt")
            }){
                Text("Sign Up")
                    .frame(maxWidth: .infinity)
            }.uniformButt().padding(.top, 200)
            Button("Already Have an account? Log In"){
                print("log in")
            }.foregroundColor(.white)
        }.cStyle1()
    }
}

#Preview {
    signUp()
}
