//
//  SplashView.swift
//  BettrApp
//
//  Created by Finbar McCarron on 6/20/25.
//

import SwiftUI

struct SplashView: View {
    @State private var showBettr = false
    @State private var showBeBettr = false
    @State private var accountability = false
    @State private var friends = false
    var onComplete: (() -> Void)?
    
    
    var body: some View {
        
        ZStack{
            Text("BETTR.")
                .textStyleBig()
                .opacity(showBettr ? 1:0)
                .onAppear(){
                    dispatchWithAnimation($showBettr)
                    hideText($showBettr, delay: 1.5, effectDuration: 1.0)
                    dispatchWithAnimation($showBeBettr,delay: 2.5, effectDuration: 1.0)
                    
                }.padding(.leading,20);
            if showBeBettr{
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
            
        }.cStyle1()
    }
}

func dispatchWithAnimation(_ binding: Binding<Bool>, delay: TimeInterval = 0.0, effectDuration: TimeInterval = 0.3) {
    if delay > 0.0 {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation (.easeIn(duration: effectDuration)){
                binding.wrappedValue = true
            }
        }
    } else {
        withAnimation (.easeInOut(duration: effectDuration)){
            binding.wrappedValue = true
        }
    }
}

func hideText(_ binding: Binding<Bool>, delay: TimeInterval = 0.0, effectDuration: TimeInterval = 0.3) {
    
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        withAnimation (.easeIn(duration: effectDuration)){
            binding.wrappedValue = false
        }
    }
    
}



#Preview {
    SplashView()
}
