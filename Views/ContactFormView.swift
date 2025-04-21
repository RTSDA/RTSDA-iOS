import SwiftUI

struct ContactFormView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ContactFormViewModel()
    @FocusState private var focusedField: Field?
    var isModal: Bool = false
    
    enum Field {
        case firstName, lastName, email, phone, message
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Use this form to get in touch with us for any reason - whether you have questions, need prayer, want to request Bible studies, learn more about our church, or would like to connect with our pastoral team.")
                        .foregroundColor(.secondary)
                }
                
                Section {
                    TextField("First Name (Required)", text: $viewModel.firstName)
                        .focused($focusedField, equals: .firstName)
                        .textContentType(.givenName)
                    
                    TextField("Last Name (Required)", text: $viewModel.lastName)
                        .focused($focusedField, equals: .lastName)
                        .textContentType(.familyName)
                    
                    TextField("Email (Required)", text: $viewModel.email)
                        .focused($focusedField, equals: .email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                    if !viewModel.email.isEmpty && !viewModel.isValidEmail(viewModel.email) {
                        Text("Please enter a valid email address")
                            .foregroundColor(.red)
                    }
                    
                    TextField("Phone", text: $viewModel.phone)
                        .focused($focusedField, equals: .phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        .onChange(of: viewModel.phone) { oldValue, newValue in
                            viewModel.phone = viewModel.formatPhoneNumber(newValue)
                        }
                    if !viewModel.phone.isEmpty && !viewModel.isValidPhone(viewModel.phone) {
                        Text("Please enter a valid phone number")
                            .foregroundColor(.red)
                    }
                }
                
                Section(header: Text("Message (Required)")) {
                    TextEditor(text: $viewModel.message)
                        .focused($focusedField, equals: .message)
                        .frame(minHeight: 100)
                }
                
                Section {
                    Button(action: {
                        Task {
                            focusedField = nil // Dismiss keyboard
                            await viewModel.submit()
                        }
                    }) {
                        HStack {
                            Spacer()
                            Text("Submit")
                            Spacer()
                        }
                    }
                    .disabled(!viewModel.isValid || viewModel.isSubmitting)
                }
            }
            .navigationTitle("Contact Us")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isModal {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            focusedField = nil
                            dismiss()
                        }
                    }
                }
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                Text(viewModel.error ?? "")
            }
            .alert("Success", isPresented: $viewModel.isSubmitted) {
                Button("OK") {
                    viewModel.reset()
                }
            } message: {
                Text("Thank you for your message! We'll get back to you soon.")
            }
        }
    }
}

class ContactFormViewModel: ObservableObject {
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var email = ""
    @Published var phone = ""
    @Published var message = ""
    @Published var error: String?
    @Published var isSubmitting = false
    @Published var isSubmitted = false
    
    var isValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !email.isEmpty &&
        isValidEmail(email) &&
        !message.isEmpty &&
        (phone.isEmpty || isValidPhone(phone))
    }
    
    func reset() {
        // Reset all fields
        firstName = ""
        lastName = ""
        email = ""
        phone = ""
        message = ""
        
        // Reset state
        error = nil
        isSubmitting = false
        isSubmitted = false
    }
    
    func formatPhoneNumber(_ value: String) -> String {
        // Remove all non-digits
        let digits = value.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        // Format the number
        if digits.isEmpty {
            return ""
        } else if digits.count < 10 {
            return digits
        } else {
            let areaCode = digits.prefix(3)
            let middle = digits.dropFirst(3).prefix(3)
            let last = digits.dropFirst(6).prefix(4)
            return "(\(areaCode)) \(middle)-\(last)"
        }
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    func isValidPhone(_ phone: String) -> Bool {
        let phoneRegex = "^\\([0-9]{3}\\) [0-9]{3}-[0-9]{4}$"
        let phonePredicate = NSPredicate(format:"SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: phone)
    }
    
    @MainActor
    func submit() async {
        guard isValid else { return }
        
        isSubmitting = true
        error = nil
        
        do {
            let url = URL(string: "https://contact.rockvilletollandsda.church/api/contact")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let payload = [
                "first_name": firstName,
                "last_name": lastName,
                "email": email,
                "phone": phone,
                "message": message
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            
            isSubmitted = true
            reset()
            
        } catch {
            self.error = "There was an error submitting your message. Please try again."
            print("Error submitting form:", error)
            reset()
        }
        
        isSubmitting = false
    }
} 