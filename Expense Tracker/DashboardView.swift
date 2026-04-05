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
            
            // --- 2. DYNAMIC PIE CHART ---
            if categoryTotals.isEmpty {
                Text("No expenses this month yet.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
            } else {
                VStack {
                    // Removed the text label here because the automatic legend does the job!
                    
                    Chart(categoryTotals, id: \.category) { item in
                        SectorMark(
                            angle: .value("Amount", item.amount),
                            innerRadius: .ratio(0.55),
                            angularInset: 1.5
                        )
                        .cornerRadius(4) // Softens the edges of the slices
                        .foregroundStyle(by: .value("Category", item.category))
                        
                        // Add the exact dollar amount inside each slice
                        .annotation(position: .overlay) {
                            Text(String(format: "$%.0f", item.amount))
                                .font(.caption2)
                                .bold()
                                .foregroundColor(.white)
                                .shadow(radius: 2) // Helps text stand out on lighter colors
                        }
                    }
                    .frame(height: 200) // ⭐️ Increased height so the circle has room to breathe
                    // Notice we removed .chartLegend(.hidden)! Now Apple will auto-generate a sleek legend.
                }
                .padding(.bottom, 20)
            }
        }
        .padding(.horizontal)
    }
}
