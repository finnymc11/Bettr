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
struct borderedTextField: ViewModifier {
	func body(content: Content) -> some View {
		content
			.padding(10)
			.background(
				RoundedRectangle(cornerRadius: 10)
					.stroke(Color.gray, lineWidth: 0.5)
			)
			.foregroundStyle(Color.white)
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
struct settingsButt: ViewModifier{
	func body(content: Content) -> some View {
		content.foregroundStyle(Color.white)
			.frame(maxWidth: .infinity).padding(10)
			.overlay(RoundedRectangle(cornerRadius: 5)
				.stroke(Color.gray, lineWidth: 1))
			.frame(maxWidth: .infinity)
	}
}
struct customNavBar: ViewModifier{
	func body(content: Content) -> some View{
		content.onAppear{
			let appearance = UINavigationBarAppearance()
			appearance.backgroundColor = .black
			appearance.shadowColor = .clear // Hides the bottom line
			appearance.titleTextAttributes = [
				.foregroundColor: UIColor.white,
				.font: UIFont.systemFont(ofSize: 40, weight: .heavy)
			]
			UINavigationBar.appearance().standardAppearance = appearance
			UINavigationBar.appearance().scrollEdgeAppearance = appearance
			appearance.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 10)
		}

	}
}
extension View{
	func navBarStyle() -> some View{
		self.modifier(customNavBar())
	}
	func settingsButtStyle() -> some View{
		self.modifier(settingsButt())
	}
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
	func borderedTField()->some View{
		self.modifier(borderedTextField())
	}
}
