import SwiftUI
import MessageUI

struct PrayerRequestView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.sizeCategory) private var sizeCategory
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var formattedPhone = ""
    @State private var requestType = PrayerRequest.RequestType.personal
    @State private var details = ""
    @State private var isConfidential = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false
    @State private var isSubmitting = false
    @State private var phoneError: String? = nil
    
    private let service = PrayerRequestService.shared
    
    private var isValidForm: Bool {
        // Name is only required if not submitting anonymously
        let isNameValid = isConfidential || !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        return isNameValid &&
        (!email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? isValidEmail(email) : true) &&
        phoneError == nil &&
        !details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func isValidPhone(_ phone: String) -> Bool {
        if phone.isEmpty { return true } // Optional field
        let phoneRegex = #"^(\+\d{1,2}\s?)?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}$"#
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: phone)
    }
    
    private func formatPhoneNumber(_ input: String) -> String {
        // Strip all non-digits
        let digitsOnly = input.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        // Format as (XXX) XXX-XXXX if we have enough digits
        switch digitsOnly.count {
        case 0:
            return ""
        case 1...3:
            return "(\(digitsOnly)"
        case 4...6:
            return "(\(digitsOnly.prefix(3))) \(digitsOnly.dropFirst(3))"
        case 7...10:
            let area = digitsOnly.prefix(3)
            let prefix = digitsOnly.dropFirst(3).prefix(3)
            let number = digitsOnly.dropFirst(6).prefix(4)
            return "(\(area)) \(prefix)-\(number)"
        default:
            // Truncate to 10 digits if longer
            let truncated = String(digitsOnly.prefix(10))
            return formatPhoneNumber(truncated)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Contact Information").font(.body)) {
                    if isConfidential {
                        Text("Your prayer request will be submitted anonymously")
                            .font(.body)
                            .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                            .foregroundColor(.secondary)
                    }
                    
                    if !isConfidential {
                        TextField("Your Name", text: $name)
                            .font(.body)
                            .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                            .textContentType(.name)
                            .submitLabel(.next)
                            .accessibilityLabel("Name field")
                    }
                    
                    Toggle("Submit Anonymously", isOn: $isConfidential)
                        .accessibilityHint("Enable to submit your prayer request without your name")
                    
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .font(.body)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                        .accessibilityLabel("Email field")
                    
                    TextField("Phone (Optional)", text: Binding(
                        get: { phone },
                        set: { newValue in
                            let formatted = formatPhoneNumber(newValue)
                            phone = formatted
                            phoneError = isValidPhone(formatted) ? nil : "Please enter a valid phone number"
                        }
                    ))
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .font(.body)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                    .accessibilityLabel("Phone field (Optional)")
                    
                    if let error = phoneError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section(header: Text("Request Details").font(.body)) {
                    Picker("Type of Request", selection: $requestType) {
                        ForEach(PrayerRequest.RequestType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                                .font(.body)
                                .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                        }
                    }
                    
                    TextEditor(text: $details)
                        .frame(height: sizeCategory.isAccessibilityCategory ? 200 : 150)
                        .font(.body)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                        .accessibilityLabel("Prayer request text")
                }
                
                Section {
                    Button(action: { Task { await submitRequest() } }) {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Submit Prayer Request")
                                .font(.body)
                                .fontWeight(.semibold)
                                .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .disabled(!isValidForm || isSubmitting)
                }
            }
            .navigationTitle("Prayer Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.body)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
                    .font(.body)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility5)
            }
            .alert("Request Submitted", isPresented: $showingSuccess) {
                Button("OK", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("Thank you for your prayer request. We will be praying for you.")
                    .font(.body)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility5)
            }
        }
    }
    
    private func submitRequest() async {
        isSubmitting = true
        
        let request = PrayerRequest(
            id: UUID().uuidString,
            name: isConfidential ? "Anonymous" : name,
            email: email,
            phone: phone,
            request: details,
            isPrivate: isConfidential,
            requestType: requestType
        )
        
        do {
            let success = try await service.submitRequest(request)
            if success {
                showingSuccess = true
            } else {
                errorMessage = "Failed to submit prayer request. Please try again."
                showingError = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
        
        isSubmitting = false
    }
}

#Preview {
    PrayerRequestView()
}