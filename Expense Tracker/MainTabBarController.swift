//
//  MainTabBarController.swift
//  Expense Tracker
//
//  Created by Apurva Rajdeep Mhatre on 4/5/26.
//

import SwiftUI
import UIKit

class MainTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. Setup the Expenses Tab
        let expensesVC = ExpenseTrackerViewController()
        let expensesNav = UINavigationController(rootViewController: expensesVC)
        expensesNav.tabBarItem = UITabBarItem(title: "Expenses", image: UIImage(systemName: "list.bullet.rectangle"), tag: 0)

        // 2. Setup the Analytics Tab
        let analyticsView = AnalyticsView()
        let analyticsVC = UIHostingController(rootView: analyticsView)
        analyticsVC.tabBarItem = UITabBarItem(title: "Analytics", image: UIImage(systemName: "chart.pie.fill"), tag: 1)

        // 3. Setup the Settings Tab
        let settingsView = SettingsView()
        let settingsVC = UIHostingController(rootView: settingsView)
        settingsVC.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gear"), tag: 2)

        // 4. Add them to the Tab Bar
        viewControllers = [expensesNav, analyticsVC, settingsVC]

        // 4. Make the tab bar look modern
        tabBar.tintColor = .systemBlue
        tabBar.backgroundColor = .systemGroupedBackground
    }
}
