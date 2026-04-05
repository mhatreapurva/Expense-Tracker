//
//  DashboardView.swift
//  Expense Tracker
//
//  Created by Apurva Rajdeep Mhatre on 4/5/26.
//

import SwiftUI
import Charts

struct DashboardView: View {
    var expenses: [Expense]
    
    // Calculate the total for the text label
    var currentMonthTotal: Double {
        let calendar = Calendar.current
        let now = Date()
        return expenses.filter {
            calendar.isDate($0.date, equalTo: now, toGranularity: .month) &&
            calendar.isDate($0.date, equalTo: now, toGranularity: .year)
        }.reduce(0) { $0 + $1.amount }
    }
    
    // Group the data for the chart
    var categoryTotals: [(category: String, amount: Double)] {
        let calendar = Calendar.current
        let now = Date()
        let currentMonthExpenses = expenses.filter {
            calendar.isDate($0.date, equalTo: now, toGranularity: .month) &&
            calendar.isDate($0.date, equalTo: now, toGranularity: .year)
        }
        
        let grouped = Dictionary(grouping: currentMonthExpenses, by: { $0.category })
        return grouped.map { (key, value) in
            (category: key, amount: value.reduce(0) { $0 + $1.amount })
        }.sorted { $0.amount > $1.amount }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            
            // --- 1. TOTAL SPEND HEADER ---
            VStack(spacing: 4) {
                Text("\(Date().formatted(.dateTime.month(.wide))) Spending")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(String(format: "$%.2f", currentMonthTotal))
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.primary)
            }
            .padding(.top, 20)
            
            // --- 2. DYNAMIC CHART ---
            if categoryTotals.isEmpty {
                // Clean empty state if there is no data
                Text("No expenses this month yet.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
            } else {
                VStack(alignment: .leading) {
                    Text("Spending by Category")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Chart(categoryTotals, id: \.category) { item in
                        BarMark(
                            x: .value("Amount", item.amount),
                            y: .value("Category", item.category)
                        )
                        .foregroundStyle(by: .value("Category", item.category))
                        .cornerRadius(4)
                        .annotation(position: .trailing) {
                            Text(String(format: "$%.0f", item.amount))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(height: 120)
                    .chartLegend(.hidden)
                }
                .padding(.bottom, 20)
            }
        }
        .padding(.horizontal)
    }
}
