//
//  pieChartView.swift
//  activityReport
//
//  Created by CJ Balmaceda on 7/14/25.
//
import SwiftUI
import DeviceActivity
import ManagedSettings
import Charts
import Foundation
struct pieSliceData{
    var startAngle: Angle
    var endAngle: Angle
    var color: Color
}
struct pieSliceView: View{
    var sliceData : pieSliceData
    var midRadians: Double{
        return Double.pi / 2.0 - (sliceData.startAngle + sliceData.endAngle).radians / 2.0
    }
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Path { path in
                    let width: CGFloat = min(geometry.size.width, geometry.size.height)
                    let height = width
                    let center = CGPoint(x: width * 0.5, y: height * 0.5)
                    path.move(to: center)
                    path.addArc(
                        center: center,
                        radius: width * 0.4,
                        startAngle: Angle(degrees: -90.0) + sliceData.startAngle,
                        endAngle: Angle(degrees: -90.0) + sliceData.endAngle,
                        clockwise: false)
                }
                .fill(sliceData.color)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
struct PieChartView: View {
    let totalActivity: Double
    let totalHours: Double
    var hours: Int{
        return Int(totalActivity)
    }
    var fractionalHour: Double {
        return totalActivity - Double(hours)
    }
    var  minutes: Int {
        return Int(fractionalHour * 60 + 0.5) // Rounding to the nearest minute
    }
    var mainSlice: pieSliceData {
        let endDeg: Double = 0
        let degrees: Double = totalActivity * 360 / totalHours
        return pieSliceData(startAngle: Angle(degrees: endDeg), endAngle: Angle(degrees: endDeg + degrees), color: hours >= Int(totalHours) ? .red : Color(red: 0.0666, green: 0.8275, blue: 0.6667))
    }
    public var widthFraction: CGFloat = 0.75
    public var innerRadiusFraction: CGFloat = 0.60
    struct Configuration {
        let totalUsageByCat: [ActivityCategory:TimeInterval]
    }
    @State private var activeIndex: Int = -1
    var body: some View {
        GeometryReader { geometry in
            ZStack{
                pieSliceView(sliceData: mainSlice)
                    .frame(width: geometry.size.width, height: geometry.size.width)
                Circle()
                    .fill(.black)
                    .frame(width: geometry.size.width * innerRadiusFraction, height: geometry.size.width * innerRadiusFraction)
                VStack {
                    Text("\(hours)h \(minutes)m")
                        .foregroundColor(hours >= Int(totalHours) ? .red : .white) // if over time change color to red
                        .padding(.top, 0)
                        .font(.title)
                    Divider().background(hours >= Int(totalHours) ? .red : .gray) // if over time change color to red
                        .frame(width: 60)
                    Text("of \(Int(totalHours))h")
                        .foregroundColor(hours >= Int(totalHours) ? .red: .white)   // if over time change color to red
                }
            }
            .background(.black)
            .foregroundColor(Color.white)
        }
    }
}
