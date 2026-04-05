//
//  DateFilterView.swift
//  Expense Tracker
//
//  Created by Apurva Rajdeep Mhatre on 4/5/26.
//

import SwiftUI

struct DateFilterView: View {
    // Allows the view to dismiss itself
    @Environment(\.dismiss) var dismiss

    // Local state for the pickers
    @State var startDate: Date
    @State var endDate: Date

    // A closure to send the chosen dates back to your main controller
    var onApply: (Date, Date) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Date Range")) {
                    // Apple's modern, compact date pickers
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        .datePickerStyle(.compact)

                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                }

                Section {
                    Button(action: {
                        onApply(startDate, endDate)
                        dismiss()
                    }) {
                        Text("Apply Filter")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .fontWeight(.semibold)
                    }

                    Button(action: {
                        // Calculate 30 days ago for the reset button
                        let thirtyDaysAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
                        onApply(thirtyDaysAgo, Date())
                        dismiss()
                    }) {
                        Text("Reset to Last 30 Days")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Filter Expenses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
