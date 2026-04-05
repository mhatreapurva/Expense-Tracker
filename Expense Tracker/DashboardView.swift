import SwiftUI
import Charts

struct DashboardView: View {
    var expenses: [Expense]
    
    var currentTotal: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    var categoryTotals: [(category: String, amount: Double)] {
        let grouped = Dictionary(grouping: expenses, by: { $0.category })
        return grouped.map { (key, value) in
            (category: key, amount: value.reduce(0) { $0 + $1.amount })
        }.sorted { $0.amount > $1.amount }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            
            // --- 1. TOTAL SPEND HEADER ---
            VStack(spacing: 4) {
                Text("Selected Range Spending")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(String(format: "$%.2f", currentTotal))
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.primary)
            }
            .padding(.top, 20)
            
            // --- 2. DYNAMIC PIE CHART ---
            if categoryTotals.isEmpty {
                Text("No expenses in this range.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
            } else {
                VStack {
                    Chart(categoryTotals, id: \.category) { item in
                        SectorMark(
                            angle: .value("Amount", item.amount),
                            innerRadius: .ratio(0.55),
                            angularInset: 1.5
                        )
                        .cornerRadius(4)
                        .foregroundStyle(by: .value("Category", item.category))
                        
                        .annotation(position: .overlay) {
                            // ⭐️ THE FIX: The Threshold Filter
                            // Only show the label if this category represents more than 6% of the total spend
                            if item.amount > (currentTotal * 0.06) {
                                Text(String(format: "$%.0f", item.amount))
                                    .font(.caption2)
                                    .bold()
                                    .foregroundColor(.white)
                                    .shadow(radius: 2)
                            }
                        }
                    }
                    .frame(height: 200)
                }
                .padding(.bottom, 20)
            }
        }
        .padding(.horizontal)
    }
}
