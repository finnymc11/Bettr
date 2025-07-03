//
//  logIn.swift
//  Bettr
//
//  Created by CJ Balmaceda on 6/27/25.
//

import Foundation
import SwiftUI

struct logInView : View{
    @EnvironmentObject var auth: fireAuth
    @Binding var currentScreen: BettrApp.Screen
    @State private var errorMessage: String? = nil
    @State private var email: String = ""
    @State private var passWord: String = ""
    var body: some View{
        VStack{
            HStack{
                Button(action: {
                    print("bruh")
                    currentScreen = .signUp
                }){
                    Text(.init(systemName: "chevron.left")).font(.system(size: 30)).foregroundStyle(Color.white)
                }.padding()
                Spacer()
            }
            Text("Welcome Back")
                .foregroundStyle(Color.white).font(.system(size: 35,weight: .thin, design: .default)).frame(maxWidth: .infinity, alignment: .center)
            
            Spacer()
            TextField(
                "Email",
                text: $email,
                prompt: Text("Email").foregroundStyle(Color.white.opacity(0.7))
            ).borderedTField()
                .padding()
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)

            
            SecureField(
                "Password",
                text: $passWord,
                prompt: Text("Password").foregroundStyle(Color.white.opacity(0.7))
            )
            .borderedTField()
            .padding()
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            Button(action: {
                print("Create account butt")
               
                auth.signIn(email: email, password: passWord) { success, error in
                    if success {
                        print("logIn  successful")
                        withAnimation{
                            currentScreen = .home
                        }
                        
                    } else {
                        errorMessage = error?.localizedDescription ?? "Unknown error occurred."
                    }
                }
            }) {
                Text("Log In")
                    .frame(maxWidth: .infinity)


            }
            .uniformButt().padding(.horizontal,30)
            .padding(.bottom, 100)
        }.cStyle1()
    }
}

#Preview {
    logInView(currentScreen: .constant(BettrApp.Screen.logIn))
}
