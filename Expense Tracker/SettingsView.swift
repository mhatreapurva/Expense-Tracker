//
//  SettingsView.swift
//  Expense Tracker
//
//  Created by Apurva Rajdeep Mhatre on 4/5/26.
//

import SwiftUI
import AuthenticationServices

struct SettingsView: View {
    // These automatically save to UserDefaults!
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("currencySymbol") private var currencySymbol: String = "$"

    // A dictionary to map full names to their symbols
    let currencies = [
        "US Dollar ($)": "$",
        "Euro (€)": "€",
        "British Pound (£)": "£",
        "Indian Rupee (₹)": "₹",
        "Japanese Yen (¥)": "¥"
    ]

    var body: some View {
        NavigationView {
            Form {
                // --- PROFILE SECTION ---
                Section(header: Text("Profile"), footer: Text("Your name is securely pulled from your Apple ID.")) {
                    if userName.isEmpty {
                        // The Native Apple Sign In Button
                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.fullName]
                        } onCompletion: { result in
                            switch result {
                            case .success(let authResults):
                                if let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential {
                                    // ⚠️ CRITICAL iOS QUIRK: Apple ONLY gives you the name the VERY FIRST time you sign in!
                                    if let givenName = appleIDCredential.fullName?.givenName,
                                       let familyName = appleIDCredential.fullName?.familyName {
                                        userName = "\(givenName) \(familyName)"
                                    } else {
                                        userName = "Apple User" // Fallback if they hid their name or signed in before
                                    }
                                }
                            case .failure(let error):
                                print("Authorization failed: \(error.localizedDescription)")
                            }
                        }
                        .frame(height: 45)
                    } else {
                        // Logged In State
                        HStack {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)

                            Text(userName)
                                .font(.headline)
                                .padding(.leading, 8)

                            Spacer()

                            Button("Sign Out") {
                                userName = "" // Clears the setting to show the button again
                            }
                            .foregroundColor(.red)
                            .font(.subheadline)
                        }
                        .padding(.vertical, 4)
                    }
                }

                // --- PREFERENCES SECTION ---
                Section(header: Text("Preferences")) {
                    Picker("Currency", selection: $currencySymbol) {
                        // Sort the keys alphabetically for the picker
                        ForEach(currencies.keys.sorted(), id: \.self) { key in
                            Text(key).tag(currencies[key]!)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
