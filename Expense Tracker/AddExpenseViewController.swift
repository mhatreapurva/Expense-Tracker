import UIKit

class AddExpenseViewController: UIViewController {
    
    weak var delegate: AddExpenseDelegate?
    
    private let nameField = UITextField()
    private let amountField = UITextField()
    
    // 1. Add Category UI Elements
    private let categoryField = UITextField()
    private let categoryPicker = UIPickerView()
    private let categories = ["Food", "Travel", "Miscellaneous"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = "New Expense"
        
        setupNavigationBar()
        setupUI()
        setupCategoryPicker()
    }
    
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
    }
    
    private func setupUI() {
        // 2. Add categoryField to the stack
        let stack = UIStackView(arrangedSubviews: [nameField, amountField, categoryField])
        stack.axis = .vertical
        stack.spacing = 16
        stack.distribution = .fillEqually
        
        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        // Styling the text fields
        [nameField, amountField, categoryField].forEach {
            $0.backgroundColor = .white
            $0.textColor = .black // THE FIX: Forces text to be black even in Dark Mode
            $0.borderStyle = .roundedRect
            $0.clearButtonMode = .whileEditing
        }
        
        nameField.placeholder = "Expense Name (e.g. Netflix)"
        amountField.placeholder = "Amount (e.g. 15.99)"
        amountField.keyboardType = .decimalPad
        categoryField.placeholder = "Select Category"
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.heightAnchor.constraint(equalToConstant: 160) // Increased height to fit 3 fields
        ])
        
        nameField.becomeFirstResponder()
    }
    
    // 3. Configure the Picker
    private func setupCategoryPicker() {
        categoryPicker.delegate = self
        categoryPicker.dataSource = self
        
        // This makes the text field show the picker instead of a keyboard!
        categoryField.inputView = categoryPicker
        
        // Create a toolbar with a "Done" button to dismiss the picker
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissPicker))
        toolbar.setItems([doneButton], animated: false)
        categoryField.inputAccessoryView = toolbar
    }
    
    @objc private func dismissPicker() {
        view.endEditing(true)
    }
    
    @objc private func saveTapped() {
        // 4. Update the guard to also check the category field
        guard let name = nameField.text, !name.isEmpty,
              let amountText = amountField.text, let amount = Double(amountText),
              let category = categoryField.text, !category.isEmpty else { return }
        
        let newExpense = Expense(name: name, amount: amount, category: category)
        
        delegate?.didAddExpense(newExpense)
        dismiss(animated: true)
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
}

// MARK: - UIPickerView Delegate & DataSource
// 5. This tells the picker how many rows to show and what text to display
extension AddExpenseViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1 // One column
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return categories.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return categories[row]
    }
    
    // When the user scrolls to a category, put that text into the text field
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        categoryField.text = categories[row]
    }
}
