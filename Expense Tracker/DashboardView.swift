import SwiftUI
import Charts

struct DashboardView: View {
    var expenses: [Expense]
    var selectedCategory: String?
    var onCategorySelected: (String?) -> Void

    @State private var rawSelectedAngle: Double?

    var currentTotal: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    var categoryTotals: [(category: String, amount: Double)] {
        let grouped = Dictionary(grouping: expenses, by: { $0.category })
        return grouped.map { (key, value) in
            (category: key, amount: value.reduce(0) { $0 + $1.amount })
        }.sorted { $0.amount > $1.amount }
    }

    // Helper to find which category was tapped based on the angle
    private func getCategory(for angle: Double) -> String? {
        var cumulativeTotal: Double = 0
        for item in categoryTotals {
            cumulativeTotal += item.amount
            if angle <= cumulativeTotal {
                return item.category
            }
        }
        return nil
    }

    var body: some View {
        VStack(spacing: 20) {

            VStack(spacing: 4) {
                // Change the title dynamically if a category is selected
                Text(selectedCategory != nil ? "\(selectedCategory!) Spending" : "Selected Range Spending")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // Show either the total, or just the total for the selected category
                let displayTotal = selectedCategory != nil ? categoryTotals.first(where: { $0.category == selectedCategory })?.amount ?? 0 : currentTotal

                Text(String(format: "$%.2f", displayTotal))
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.primary)
            }
            .padding(.top, 20)

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
                            outerRadius: selectedCategory == item.category ? .ratio(1.0) : .ratio(0.9), // Pop the selected slice out slightly
                            angularInset: 1.5
                        )
                        .cornerRadius(4)
                        .foregroundStyle(by: .value("Category", item.category))
                        // Dim the unselected slices
                        .opacity(selectedCategory == nil || selectedCategory == item.category ? 1.0 : 0.3)

                        .annotation(position: .overlay) {
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
                    // The magic modifier that detects taps on the pie chart
                    .chartAngleSelection(value: $rawSelectedAngle)
                    .onChange(of: rawSelectedAngle) { _, newValue in
                        if let newAngle = newValue {
                            let tappedCategory = getCategory(for: newAngle)
                            // If they tap the same category again, toggle it off
                            if tappedCategory == selectedCategory {
                                onCategorySelected(nil)
                            } else {
                                onCategorySelected(tappedCategory)
                            }
                            // Reset the angle so they can tap again
                            rawSelectedAngle = nil
                        }
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .padding(.horizontal)
    }
}
