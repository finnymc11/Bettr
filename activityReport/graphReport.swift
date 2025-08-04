//
//  graphReport.swift
//  Bettr
//
//  Created by Finbar McCarron on 7/29/25.
//

import SwiftUI
import Charts

struct TimeGraphView: View {
    let data: [DailyScreenTime]
    @State private var threshold: Double = 2.0

    var body: some View {
        VStack(alignment: .leading) {
            Text("Past 7 Days")
                .font(.headline)
                .padding(.leading)
            Chart {
                // Blue Line for screen time
                ForEach(completeWeekData, id: \.date) { entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Hours", entry.totalHours)
                    )
                    .foregroundStyle(.blue)
                    .symbol(Circle())
                    .interpolationMethod(.monotone)
                }

                // Green Line for Goal Threshold
                RuleMark(y: .value("Goal", threshold))
                    .foregroundStyle(.green)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                    .annotation(position: .topTrailing) {
                        Text("Goal: \(threshold, specifier: "%.1f")h")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }

                // Average Line (Dynamic Color)
                RuleMark(y: .value("Average", averageHours))
                    .foregroundStyle(averageHours <= threshold ? .green : .red)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3]))
                    .annotation(position: .topTrailing) {
                        Text("Avg: \(averageHours, specifier: "%.1f")h")
                            .font(.caption2)
                            .foregroundColor(averageHours <= threshold ? .green : .red)
                    }

            }
            .id(threshold)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            }
            .chartXScale(domain: completeWeekData.first!.date...completeWeekData.last!.date.addingTimeInterval(60 * 60 * 12))
            .chartYScale(domain: 0...8)
            .chartYAxis {
                AxisMarks(values: Array(0...8)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .frame(height: 260)
            .padding(.horizontal, 16) // adds space left and right
            .padding(.trailing, 24)
            .onAppear {
                threshold = UserDefaults(suiteName: "group.com.data.bettr")?.double(forKey: "goalThreshold") ?? 2.0
                printLatestScreenTimeData()
            }
        }
    }

    // MARK: - Computed Week-Aligned Data

    private var completeWeekData: [DailyScreenTime] {
        let calendar = Calendar.current
        let today = Date()
        
        // Find Sunday of the current week
        let weekday = calendar.component(.weekday, from: today)
        let sunday = calendar.date(byAdding: .day, value: -(weekday - 1), to: calendar.startOfDay(for: today))!

        // Build full week [Sunday to Saturday]
        let weekDates = (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: sunday)
        }

        // Create a lookup for your data
        let dataDict = Dictionary(uniqueKeysWithValues: data.map { (Calendar.current.startOfDay(for: $0.date), $0.totalHours) })

        // Fill in missing days with 0
        return weekDates.map { date in
            DailyScreenTime(date: date, totalHours: dataDict[calendar.startOfDay(for: date)] ?? 0)
        }
    }
    private var averageHours: Double {
        let nonZeroEntries = completeWeekData.filter { $0.totalHours > 0 }
        let total = nonZeroEntries.reduce(0) { $0 + $1.totalHours }
        return nonZeroEntries.isEmpty ? 0 : total / Double(nonZeroEntries.count)
    }
}
