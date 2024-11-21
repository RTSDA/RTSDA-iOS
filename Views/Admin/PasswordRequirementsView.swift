import SwiftUI

struct PasswordRequirementsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    RequirementRow(text: "At least 12 characters long", icon: "ruler")
                    RequirementRow(text: "Contains uppercase letters", icon: "textformat.size.larger")
                    RequirementRow(text: "Contains lowercase letters", icon: "textformat.size.smaller")
                    RequirementRow(text: "Contains numbers", icon: "number")
                    RequirementRow(text: "Contains special characters", icon: "star")
                }
                
                Section {
                    Text("Example: MySecure@Pass123")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Password Requirements")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct RequirementRow: View {
    let text: String
    let icon: String
    
    var body: some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: icon)
        }
    }
} 