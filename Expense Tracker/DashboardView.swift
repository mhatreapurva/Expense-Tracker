import Charts
import SwiftUI

struct DashboardView: View {
    var expenses: [Expense]
    var selectedCategory: String?
    var onCategorySelected: (String?) -> Void

    @State private var rawSelectedAngle: Double?

    @AppStorage("currencySymbol") private var currencySymbol: String = "$"

    var currentTotal: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    var categoryTotals: [(category: String, amount: Double)] {
        let grouped = Dictionary(grouping: expenses, by: { $0.category })
        return grouped.map { key, value in
            (category: key, amount: value.reduce(0) { $0 + $1.amount })
        }.sorted { $0.amount > $1.amount }
    }

    var body: some View {
        VStack(spacing: 20) {
            SpendingSummaryView(
                selectedCategory: selectedCategory,
                categoryTotals: categoryTotals,
                currentTotal: currentTotal,
                currencySymbol: currencySymbol
            )
            if categoryTotals.isEmpty {
                NoExpensesView()
            } else {
                CategoryPieChartView(
                    categoryTotals: categoryTotals,
                    selectedCategory: selectedCategory,
                    currentTotal: currentTotal,
                    currencySymbol: currencySymbol,
                    rawSelectedAngle: $rawSelectedAngle,
                    onCategorySelected: onCategorySelected
                )
            }
        }
        .padding(.horizontal)
    }
}

private struct SpendingSummaryView: View {
    var selectedCategory: String?
    var categoryTotals: [(category: String, amount: Double)]
    var currentTotal: Double
    var currencySymbol: String

    var body: some View {
        VStack(spacing: 4) {
            Text(selectedCategory != nil ? "\(selectedCategory!) Spending" : "Selected Range Spending")
                .font(.subheadline)
                .foregroundColor(.secondary)

            let displayTotal = selectedCategory != nil ? categoryTotals.first(where: { $0.category == selectedCategory })?.amount ?? 0 : currentTotal

            Text(String(format: "\(currencySymbol)%.2f", displayTotal))
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.primary)
        }
        .padding(.top, 20)
    }
}

private struct NoExpensesView: View {
    var body: some View {
        Text("No expenses in this range.")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding(.bottom, 20)
    }
}

private struct CategoryPieChartView: View {
    var categoryTotals: [(category: String, amount: Double)]
    var selectedCategory: String?
    var currentTotal: Double
    var currencySymbol: String
    @Binding var rawSelectedAngle: Double?
    var onCategorySelected: (String?) -> Void

    static func getCategory(for angle: Double, in categoryTotals: [(category: String, amount: Double)]) -> String? {
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
        VStack {
            Chart(categoryTotals, id: \.category) { item in
                SectorMark(
                    angle: .value("Amount", item.amount),
                    innerRadius: .ratio(0.55),
                    outerRadius: selectedCategory == item.category ? .ratio(1.0) : .ratio(0.9),
                    angularInset: 1.5
                )
                .cornerRadius(4)
                .foregroundStyle(by: .value("Category", item.category))
                .opacity(selectedCategory == nil || selectedCategory == item.category ? 1.0 : 0.3)
                .annotation(position: .overlay) {
                    if item.amount > (currentTotal * 0.06) {
                        Text(String(format: "\(currencySymbol)%.0f", item.amount))
                            .font(.caption2)
                            .bold()
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                    }
                }
            }
            .frame(height: 200)
            .chartAngleSelection(value: $rawSelectedAngle)
            .onChange(of: rawSelectedAngle) { _, newValue in
                if let newAngle = newValue {
                    let tappedCategory = CategoryPieChartView.getCategory(for: newAngle, in: categoryTotals)
                    if tappedCategory == selectedCategory {
                        onCategorySelected(nil)
                    } else {
                        onCategorySelected(tappedCategory)
                    }
                    rawSelectedAngle = nil
                }
            }
        }
        .padding(.bottom, 20)
    }
}
