import Foundation

struct InsightsEngine {
    static func generateInsights(for filteredExpenses: [Expense], allExpenses: [Expense], filter: AnalyticsView.TimeFilter) async -> [String] {
        guard !filteredExpenses.isEmpty else {
            return ["Add more expenses to generate AI insights."]
        }
        
        let apiKey = Secrets.geminiAPIKey
        guard apiKey != "YOUR_API_KEY_HERE" && !apiKey.isEmpty else {
            return ["Please add your Gemini API key in Secrets.swift to enable AI insights!"]
        }
        
        // 1. Calculate basic metrics
        let totalSpent = filteredExpenses.reduce(0) { $0 + $1.amount }
        let currencySymbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "$"
        
        let categoryData = filteredExpenses.groupedByCategory()
        let topCategories = categoryData.prefix(3).map { "\($0.category): \(currencySymbol)\(String(format: "%.2f", $0.amount))" }.joined(separator: ", ")
        
        // 2. Calculate largest transaction
        let largestExpense = filteredExpenses.max(by: { $0.amount < $1.amount })
        let largestTransactionName = largestExpense?.name ?? "Unknown"
        let largestTransactionAmount = largestExpense?.amount ?? 0
        
        // 3. Calculate previous period spend
        var previousPeriodSpent: Double = 0
        let calendar = Calendar.current
        let now = Date()
        
        switch filter {
        case .thisMonth:
            if let startOfThisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
               let startOfLastMonth = calendar.date(byAdding: .month, value: -1, to: startOfThisMonth) {
                let previousExpenses = allExpenses.filter { $0.date >= startOfLastMonth && $0.date < startOfThisMonth }
                previousPeriodSpent = previousExpenses.reduce(0) { $0 + $1.amount }
            }
        case .last3Months:
            if let startOf3MonthsAgo = calendar.date(byAdding: .month, value: -3, to: now),
               let startOf6MonthsAgo = calendar.date(byAdding: .month, value: -6, to: now) {
                let previousExpenses = allExpenses.filter { $0.date >= startOf6MonthsAgo && $0.date < startOf3MonthsAgo }
                previousPeriodSpent = previousExpenses.reduce(0) { $0 + $1.amount }
            }
        case .thisYear:
            if let startOfThisYear = calendar.date(from: calendar.dateComponents([.year], from: now)),
               let startOfLastYear = calendar.date(byAdding: .year, value: -1, to: startOfThisYear) {
                let previousExpenses = allExpenses.filter { $0.date >= startOfLastYear && $0.date < startOfThisYear }
                previousPeriodSpent = previousExpenses.reduce(0) { $0 + $1.amount }
            }
        }
        
        let trendContext = previousPeriodSpent > 0 ? "Previous period spend: \(currencySymbol)\(String(format: "%.2f", previousPeriodSpent))" : "No previous period data available."
        
        // 4. Calculate budget remaining
        let budgetRemaining: Double
        if BudgetDefaults.getIsBudgetingEnabled() {
            let monthlyBudget = BudgetDefaults.getMonthlyBudget()
            let applicableBudget: Double
            switch filter {
            case .thisMonth: applicableBudget = monthlyBudget
            case .last3Months: applicableBudget = monthlyBudget * 3
            case .thisYear: applicableBudget = monthlyBudget * 12
            }
            budgetRemaining = applicableBudget - totalSpent
        } else {
            // Default to 0 so we don't skew the AI if budgeting is disabled
            budgetRemaining = 0
        }
        
        let budgetStatusText = BudgetDefaults.getIsBudgetingEnabled() ? 
            (budgetRemaining >= 0 ? "Under budget by \(currencySymbol)\(String(format: "%.2f", budgetRemaining))" : "Over budget by \(currencySymbol)\(String(format: "%.2f", abs(budgetRemaining)))") : 
            "Budgeting disabled."

        // 5. Build the prompt
        let prompt = """
        You are a smart, encouraging personal finance AI assistant. Analyze the following user data:

        - Current Period Spend: \(currencySymbol)\(String(format: "%.2f", totalSpent))
        - \(trendContext)
        - Top Categories: \(topCategories.isEmpty ? "None yet" : topCategories)
        - Largest Transaction: \(largestTransactionName) (\(currencySymbol)\(String(format: "%.2f", largestTransactionAmount)))
        - Budget Status: \(budgetStatusText)

        Provide exactly TWO short, unique, and highly specific financial insights or actionable tips based STRICTLY on this data. 

        Guidelines:
        1. Compare current spend to the previous period or budget if the data is available.
        2. Call out specific categories or the largest transaction if it impacts their budget.
        3. Format the response as exactly two bullet points using a dash (-).
        4. Do not include any introductory, explanatory, or concluding text. 
        5. Be concise, punchy, and use emojis appropriately.
        """
        
        // 6. Make REST Request
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(apiKey)") else {
            return ["Error: Invalid API URL."]
        }
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                var errorMessage = "Failed to connect to AI server. Status: \((response as? HTTPURLResponse)?.statusCode ?? 0)"
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorDict = json["error"] as? [String: Any],
                   let message = errorDict["message"] as? String {
                    errorMessage += "\nReason: \(message)"
                }
                return ["Error: \(errorMessage)"]
            }
            
            // Parse JSON response
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let candidates = json["candidates"] as? [[String: Any]],
               let firstCandidate = candidates.first,
               let content = firstCandidate["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let firstPart = parts.first,
               let text = firstPart["text"] as? String {
                
                // Split by dash or newline and clean up
                let bulletPoints = text.components(separatedBy: "\n")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { $0.hasPrefix("-") || $0.hasPrefix("*") }
                    .map { String($0.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines) }
                
                if bulletPoints.isEmpty {
                    return [text]
                }
                return Array(bulletPoints.prefix(2))
            }
            
        } catch {
            return ["Error: \(error.localizedDescription)"]
        }
        
        return ["Unable to generate insights at this time."]
    }
}
