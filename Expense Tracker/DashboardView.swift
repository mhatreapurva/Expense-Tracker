import Charts
import SwiftUI

/// A minimalistic SwiftUI view showing the safe-to-spend amount for a given interval.
struct SafeToSpendMinimalView: View {
    let totalSpentThisMonth: Double
    let monthlyBudget: Double // Observed by parent to trigger updates
    let currencySymbol: String
    let isBudgetingEnabled: Bool
    let budgetInterval: BudgetInterval

    private var safeToSpendAmount: Double {
        SafeToSpendCalculator.calculateSafeToSpend(
            totalSpentThisMonth: totalSpentThisMonth,
            for: budgetInterval
        )
    }

    private var titleText: String {
        if !isBudgetingEnabled {
            return "Budgeting Disabled"
        }
        return "Safe to Spend \(budgetInterval.rawValue)"
    }

    private var amountText: String {
        if !isBudgetingEnabled || safeToSpendAmount.isInfinite {
            return "Unlimited"
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencySymbol = currencySymbol
            formatter.locale = Locale(identifier: "en_US") // Enforce US locale for consistent symbol placement
            return formatter.string(from: NSNumber(value: safeToSpendAmount)) ?? "\(currencySymbol)0.00"
        }
    }

    private var amountTextColor: Color {
        if !isBudgetingEnabled {
            return .secondary
        } else if safeToSpendAmount.isInfinite {
            return .green
        } else if safeToSpendAmount > 0 {
            return .green
        } else {
            return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titleText)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(amountText)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(amountTextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct DashboardView: View {
    var expenses: [Expense]
    var totalSpentInCurrentMonth: Double
    var selectedCategory: String?
    var onCategorySelected: (String?) -> Void

    @State private var rawSelectedAngle: Double?

    @AppStorage("currencySymbol") private var currencySymbol: String = "$"
    @AppStorage("monthlyBudget") private var monthlyBudget: Double = 0.0
    @AppStorage("isBudgetingEnabled") private var isBudgetingEnabled: Bool = true
    @AppStorage("budgetInterval") private var budgetInterval: BudgetInterval = .daily

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
            if isBudgetingEnabled {
                SafeToSpendMinimalView(
                    totalSpentThisMonth: totalSpentInCurrentMonth,
                    monthlyBudget: monthlyBudget,
                    currencySymbol: currencySymbol,
                    isBudgetingEnabled: isBudgetingEnabled,
                    budgetInterval: budgetInterval
                )
                .padding(.top, 10)
            }

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
        .onAppear {
            // Ensure BudgetDefaults are in sync with AppStorage on appear
            if isBudgetingEnabled != BudgetDefaults.getIsBudgetingEnabled() {
                isBudgetingEnabled = BudgetDefaults.getIsBudgetingEnabled()
            }
            if budgetInterval != BudgetDefaults.getBudgetInterval() {
                budgetInterval = BudgetDefaults.getBudgetInterval()
            }
        }
        .onChange(of: isBudgetingEnabled) { oldValue, newValue in
            BudgetDefaults.setIsBudgetingEnabled(newValue)
        }
        .onChange(of: budgetInterval) { oldValue, newValue in
            BudgetDefaults.setBudgetInterval(newValue)
        }
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
        .padding(.top, 10)
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
