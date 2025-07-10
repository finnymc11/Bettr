//
//  SplashView.swift
//  BettrApp
//
//  Created by Finbar McCarron on 6/20/25.
//

import SwiftUI

struct SplashView: View {
    //    @State private var showBettr = false
    @State private var showSplash = false
    @State private var showBeBettr = false
    @State private var accountability = false
    @State private var friends = false
    var onComplete: (() -> Void)?
    var body: some View {
        
        ZStack{
            if showSplash{
                HStack{
                    VStack(alignment: .leading, spacing: 40){
                        Text("Be Bettr.").textStyleReg().onAppear(){
                            dispatchWithAnimation($accountability, delay: 1.1, effectDuration: 1.0 )
                        }
                        if accountability{
                            Text("Monitor Your Habits.").textStyleReg().onAppear(){
                                dispatchWithAnimation($friends, delay: 2.1, effectDuration: 1.0)
                            }
                        }
                        if friends{
                            Text("Stay Accountable with friends.").textStyleReg().onAppear(){
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    onComplete?()
                                }
                            }
                        }
                    }
                    Spacer()
                }.padding(.horizontal, 10)
                
            }
            
          
        }.cStyle1().onAppear(){
            DispatchQueue.main.asyncAfter(deadline: .now()+0.5){
                withAnimation {
                    showSplash = true
                }
            }
        }
    }
}



#Preview {
    SplashView()
}
