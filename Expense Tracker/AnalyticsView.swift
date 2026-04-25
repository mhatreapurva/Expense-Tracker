import SwiftUI
import Charts

struct AnalyticsView: View {
    @State private var expenses: [Expense] = []
    
    // Time filter
    enum TimeFilter: String, CaseIterable, Identifiable {
        case thisMonth = "This Month"
        case last3Months = "Last 3 Months"
        case thisYear = "This Year"
        var id: String { rawValue }
    }
    
    @State private var selectedFilter: TimeFilter = .last3Months
    @AppStorage("currencySymbol") private var currencySymbol: String = "$"
    
    var filteredExpenses: [Expense] {
        let now = Date()
        let calendar = Calendar.current
        
        switch selectedFilter {
        case .thisMonth:
            guard let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start else { return expenses }
            return expenses.filter { $0.date >= startOfMonth }
        case .last3Months:
            guard let startOf3MonthsAgo = calendar.date(byAdding: .month, value: -3, to: now) else { return expenses }
            return expenses.filter { $0.date >= startOf3MonthsAgo }
        case .thisYear:
            guard let startOfYear = calendar.dateInterval(of: .year, for: now)?.start else { return expenses }
            return expenses.filter { $0.date >= startOfYear }
        }
    }
    
    var categoryData: [(category: String, amount: Double)] {
        filteredExpenses.groupedByCategory()
    }
    
    var dailyData: [(date: Date, amount: Double)] {
        filteredExpenses.groupedByDay()
    }
    
    var monthlyData: [(date: Date, amount: Double)] {
        filteredExpenses.groupedByMonthForBarChart()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    
                    Picker("Time Range", selection: $selectedFilter) {
                        ForEach(TimeFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    if filteredExpenses.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "chart.pie.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            Text("No expenses found for this time period.")
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 60)
                    } else {
                        // 1. Total Spent Header
                        let total = filteredExpenses.reduce(0) { $0 + $1.amount }
                        VStack(alignment: .leading) {
                            Text("Total Spent")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("\(currencySymbol)\(String(format: "%.2f", total))")
                                .font(.system(size: 34, weight: .bold))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        
                        // 2. Spending By Category (Pie Chart)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Spending by Category")
                                .font(.headline)
                            
                            if #available(iOS 17.0, *) {
                                Chart {
                                    ForEach(categoryData, id: \.category) { item in
                                        SectorMark(
                                            angle: .value("Amount", item.amount),
                                            innerRadius: .ratio(0.6),
                                            angularInset: 1.5
                                        )
                                        .foregroundStyle(by: .value("Category", item.category))
                                        .annotation(position: .overlay) {
                                            if (item.amount / total) > 0.05 {
                                                Text("\(Int((item.amount / total) * 100))%")
                                                    .font(.caption.bold())
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                }
                                .frame(height: 250)
                            } else {
                                // Fallback bar chart for < iOS 17
                                Chart {
                                    ForEach(categoryData, id: \.category) { item in
                                        BarMark(
                                            x: .value("Amount", item.amount),
                                            y: .value("Category", item.category)
                                        )
                                        .foregroundStyle(by: .value("Category", item.category))
                                    }
                                }
                                .frame(height: 250)
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        // 3. Daily Trend (Line Chart)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Daily Spend Trend")
                                .font(.headline)
                            
                            Chart {
                                ForEach(dailyData, id: \.date) { item in
                                    LineMark(
                                        x: .value("Date", item.date),
                                        y: .value("Amount", item.amount)
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(Color.blue)
                                    
                                    AreaMark(
                                        x: .value("Date", item.date),
                                        y: .value("Amount", item.amount)
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.4), Color.blue.opacity(0.0)]), startPoint: .top, endPoint: .bottom))
                                }
                            }
                            .frame(height: 200)
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day, count: 5)) { _ in
                                    AxisGridLine()
                                    AxisTick()
                                    AxisValueLabel(format: .dateTime.day().month())
                                }
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        // 4. Monthly Comparison (Bar Chart)
                        if selectedFilter == .last3Months || selectedFilter == .thisYear {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Monthly Comparison")
                                    .font(.headline)
                                
                                Chart {
                                    ForEach(monthlyData, id: \.date) { item in
                                        BarMark(
                                            x: .value("Month", item.date, unit: .month),
                                            y: .value("Amount", item.amount)
                                        )
                                        .foregroundStyle(Color.green)
                                        .cornerRadius(4)
                                    }
                                }
                                .frame(height: 200)
                                .chartXAxis {
                                    AxisMarks(values: .stride(by: .month)) { _ in
                                        AxisGridLine()
                                        AxisTick()
                                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                                    }
                                }
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(16)
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Analytics")
            .background(Color(UIColor.systemGroupedBackground))
            .onAppear(perform: loadData)
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ExpensesUpdated"))) { _ in
                loadData()
            }
        }
    }
    
    private func loadData() {
        if let savedData = UserDefaults.standard.data(forKey: "savedExpenses"),
           let decodedExpenses = try? JSONDecoder().decode([Expense].self, from: savedData) {
            self.expenses = decodedExpenses
        } else {
            self.expenses = []
        }
    }
}
