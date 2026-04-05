//
//  MainTabBarController.swift
//  Expense Tracker
//
//  Created by Apurva Rajdeep Mhatre on 4/5/26.
//

import UIKit
import SwiftUI

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. Setup the Expenses Tab
        let expensesVC = ExpenseTrackerViewController()
        let expensesNav = UINavigationController(rootViewController: expensesVC)
        expensesNav.tabBarItem = UITabBarItem(title: "Dashboard", image: UIImage(systemName: "chart.pie.fill"), tag: 0)

        // 2. Setup the Settings Tab (Bridging the SwiftUI view we just made)
        let settingsView = SettingsView()
        let settingsVC = UIHostingController(rootView: settingsView)
        settingsVC.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gear"), tag: 1)

        // 3. Add them to the Tab Bar
        viewControllers = [expensesNav, settingsVC]

        // 4. Make the tab bar look modern
        tabBar.tintColor = .systemBlue
        tabBar.backgroundColor = .systemGroupedBackground
    }
}
