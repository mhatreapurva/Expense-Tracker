import UIKit



class AddExpenseViewController: UIViewController {

    weak var delegate: AddExpenseDelegate?

    private let nameField = UITextField()
    private let amountField = UITextField()

    // 1. Replaced UITextField with a UIButton for the modern Dropdown Menu
    private let categoryButton = UIButton(type: .system)
    private var selectedCategory: String = "Housing" // Default category
    
    private let categories = [
        "Housing", "Utilities", "Groceries", "Food & Dining",
        "Travel", "Entertainment", "Shopping", "Health", "Miscellaneous"
    ]
    
    private let datePicker = UIDatePicker()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = "New Expense"

        setupNavigationBar()
        setupUI()
        setupCategoryMenu() // 2. New setup function
    }

    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
    }

    private func setupUI() {
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact
        datePicker.tintColor = .systemBlue
        datePicker.date = Date()
        datePicker.maximumDate = Date()

        let dateLabel = UILabel()
        dateLabel.text = "Date"
        dateLabel.textColor = .label
        let dateStack = UIStackView(arrangedSubviews: [dateLabel, datePicker])
        dateStack.axis = .horizontal
        dateStack.distribution = .fill
        
        // Swapped categoryField for categoryButton in the stack
        let stack = UIStackView(arrangedSubviews: [nameField, amountField, categoryButton, dateStack])
        stack.axis = .vertical
        stack.spacing = 16
        stack.distribution = .fillEqually

        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        // Style the text fields
        [nameField, amountField].forEach {
            $0.backgroundColor = .secondarySystemGroupedBackground
            $0.textColor = .label
            $0.tintColor = .systemBlue
            $0.borderStyle = .none
            $0.layer.cornerRadius = 10
            $0.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 10))
            $0.leftViewMode = .always
        }

        nameField.placeholder = "Expense Name (e.g. Netflix)"
        amountField.placeholder = "Amount (e.g. 15.99)"
        amountField.keyboardType = .decimalPad

        // Style the Button to look EXACTLY like the Text Fields
        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = .label
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        config.background.backgroundColor = .secondarySystemGroupedBackground
        config.background.cornerRadius = 10
        categoryButton.configuration = config
        categoryButton.contentHorizontalAlignment = .leading

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.heightAnchor.constraint(equalToConstant: 220)
        ])

        nameField.becomeFirstResponder()
    }

    // 3. The Magic: UIMenu setup
    private func setupCategoryMenu() {
        // Set the initial title
        categoryButton.setTitle(selectedCategory, for: .normal)
        
        // Build the dropdown options
        let menuActions = categories.map { category in
            UIAction(title: category) { [weak self] action in
                // When an item is tapped, update the state and the button's text instantly
                self?.selectedCategory = action.title
                self?.categoryButton.setTitle(action.title, for: .normal)
            }
        }
        
        // Attach the menu to the button
        categoryButton.menu = UIMenu(title: "Select Category", children: menuActions)
        categoryButton.showsMenuAsPrimaryAction = true
    }

    @objc private func saveTapped() {
        guard let name = nameField.text, !name.isEmpty,
              let amountText = amountField.text, let amount = Double(amountText) else {
            
            let alert = UIAlertController(title: "Missing Information", message: "Please ensure all fields are filled out correctly.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        // Use our selectedCategory variable directly
        let newExpense = Expense(name: name, amount: amount, category: selectedCategory, date: datePicker.date)

        delegate?.didAddExpense(newExpense)
        dismiss(animated: true)
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
}

