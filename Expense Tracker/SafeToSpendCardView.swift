import UIKit

/// A small card-style view that shows today's safe-to-spend amount.
public final class SafeToSpendCardView: UIView {

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Safe to Spend Today"
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.textColor = .label
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let amountLabel: UILabel = {
        let label = UILabel()
        label.text = "$0.00"
        label.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        label.textColor = .systemRed
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()

    private let container: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .fill
        stack.distribution = .fill
        return stack
    }()
    
    private var lastTotalSpentThisMonth: Double = 0.0
    private var currentCurrencySymbol: String = "$"
    private var currentIsBudgetingEnabled: Bool = true
    // NEW: Store the current budget interval
    private var currentBudgetInterval: BudgetInterval = .daily

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = 12
        layer.masksToBounds = true

        addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addArrangedSubview(titleLabel)
        container.addArrangedSubview(amountLabel)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            container.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            container.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }

    /// Updates the amount label using currency formatting and color rules.
    /// - Parameters:
    ///   - amount: The computed safe-to-spend amount for today.
    ///   - currencySymbol: The currency symbol to use for formatting.
    ///   - isBudgetingEnabled: A boolean indicating if budgeting is currently enabled.
    ///   - interval: The BudgetInterval (daily, weekly, monthly) for display.
    public func configure(amount: Double, currencySymbol: String, isBudgetingEnabled: Bool, interval: BudgetInterval) { // MODIFIED: Added interval
        self.currentCurrencySymbol = currencySymbol
        self.currentIsBudgetingEnabled = isBudgetingEnabled
        self.currentBudgetInterval = interval // NEW: Store interval

        if !isBudgetingEnabled {
            titleLabel.text = "Budgeting Disabled"
            amountLabel.text = "Unlimited"
            amountLabel.textColor = .secondaryLabel
        } else if amount.isInfinite {
            titleLabel.text = "Safe to Spend \(interval.rawValue)" // NEW: Title uses interval
            amountLabel.text = "Unlimited"
            amountLabel.textColor = .systemGreen
        }
        else {
            titleLabel.text = "Safe to Spend \(interval.rawValue)" // NEW: Title uses interval
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencySymbol = currencySymbol
            formatter.locale = Locale(identifier: "en_US") 

            let formatted = formatter.string(from: NSNumber(value: amount)) ?? "\(currencySymbol)0.00"
            amountLabel.text = formatted

            if amount > 0 {
                amountLabel.textColor = .systemGreen
            } else {
                amountLabel.textColor = .systemRed
            }
        }

        // Accessibility: announce the amount clearly
        amountLabel.isAccessibilityElement = true
        amountLabel.accessibilityLabel = "Safe to spend"
        amountLabel.accessibilityValue = amountLabel.text
    }

    /// Convenience initializer to set an initial amount.
    // MODIFIED: Updated convenience init to include interval
    public convenience init(amount: Double, currencySymbol: String, isBudgetingEnabled: Bool, interval: BudgetInterval) {
        self.init(frame: .zero)
        configure(amount: amount, currencySymbol: currencySymbol, isBudgetingEnabled: isBudgetingEnabled, interval: interval)
    }

    /// Computes today's safe-to-spend using the calculator and updates the view.
    /// - Parameters:
    ///   - totalSpentThisMonth: Sum of all expenses in the current month.
    ///   - date: The date to use for calculation (defaults to today).
    ///   - currencySymbol: The currency symbol to use for formatting.
    ///   - isBudgetingEnabled: A boolean indicating if budgeting is currently enabled.
    ///   - interval: The BudgetInterval (daily, weekly, monthly) for calculation and display.
    public func update(totalSpentThisMonth: Double, date: Date = Date(), currencySymbol: String, isBudgetingEnabled: Bool, interval: BudgetInterval) { // MODIFIED: Added interval
        lastTotalSpentThisMonth = totalSpentThisMonth
        self.currentCurrencySymbol = currencySymbol
        self.currentIsBudgetingEnabled = isBudgetingEnabled
        self.currentBudgetInterval = interval // NEW: Store interval

        let amount = SafeToSpendCalculator.calculateSafeToSpend(totalSpentThisMonth: totalSpentThisMonth, on: date, for: interval) // MODIFIED: Pass interval to calculator
        configure(amount: amount, currencySymbol: currencySymbol, isBudgetingEnabled: isBudgetingEnabled, interval: interval) // MODIFIED: Pass interval
    }
    
    /// Sets the monthly budget in UserDefaults and refreshes the card using the last known spending.
    /// - Parameters:
    ///   - amount: The monthly budget to store.
    ///   - date: The date to use for calculation (defaults to today).
    ///   - currencySymbol: The currency symbol to use for formatting.
    ///   - isBudgetingEnabled: A boolean indicating if budgeting is currently enabled.
    ///   - interval: The BudgetInterval (daily, weekly, monthly) for calculation and display.
    // MODIFIED: setMonthlyBudget now also takes currencySymbol, isBudgetingEnabled, and interval
    public func setMonthlyBudget(_ amount: Double, date: Date = Date(), currencySymbol: String, isBudgetingEnabled: Bool, interval: BudgetInterval) {
        BudgetDefaults.setMonthlyBudget(amount)
        let safe = SafeToSpendCalculator.calculateSafeToSpend(totalSpentThisMonth: lastTotalSpentThisMonth, on: date, for: interval) // MODIFIED: Pass interval
        configure(amount: safe, currencySymbol: currencySymbol, isBudgetingEnabled: isBudgetingEnabled, interval: interval) // MODIFIED: Pass interval
    }
}
