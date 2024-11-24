import SwiftUI
import MessageUI
import OSLog
import FirebaseFirestore

struct PrayerRequestView: View {
    private let logger = Logger(subsystem: "org.rtsda.app", category: "PrayerRequestView")
    @Environment(\.dismiss) private var dismiss
    @Environment(\.sizeCategory) private var sizeCategory
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var request = ""
    @State private var isPrivate = false
    @State private var isAnonymous = false
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var showSuccess = false
    @State private var errorMessage = ""
    @State private var nameError: String?
    @State private var emailError: String?
    @State private var phoneError: String?
    @State private var requestError: String?
    
    private let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    
    private func isValidEmail(_ email: String) -> Bool {
        if email.isEmpty { return true }
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func isValidPhone(_ phone: String) -> Bool {
        logger.debug("📱 Phone validation - Raw input: '\(phone)'")
        if phone.isEmpty { return true }
        let digits = phone.filter { $0.isNumber }
        logger.debug("📱 Phone validation - Digits only: '\(digits)', Count: \(digits.count)")
        return digits.count == 10
    }
    
    private func formatPhoneNumber(_ input: String) -> String {
        logger.debug("📱 Phone formatting - Input: '\(input)'")
        
        // Get only the digits
        var digits = input.filter { $0.isNumber }
        logger.debug("📱 Phone formatting - Digits only: '\(digits)'")
        
        // Enforce 10 digit limit
        if digits.count > 10 {
            logger.notice("📱 Phone formatting - Truncating to 10 digits")
            digits = String(digits.prefix(10))
        }
        
        // Build the formatted string
        var result = ""
        for (index, digit) in digits.enumerated() {
            switch index {
            case 0: result = "(" + String(digit)
            case 1...2: result += String(digit)
            case 3: result += ") " + String(digit)
            case 4...5: result += String(digit)
            case 6: result += "-" + String(digit)
            case 7...9: result += String(digit)
            default: break
            }
        }
        
        logger.debug("📱 Phone formatting - Final result: '\(result)'")
        return result
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if !isAnonymous {
                    Section {
                        TextField("Name", text: $name)
                            .textContentType(.name)
                            .autocorrectionDisabled()
                            .onChange(of: name) { _, _ in
                                nameError = name.isEmpty ? "Please enter your name" : nil
                            }
                        if let error = nameError {
                            Text(error)
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                    }
                }
                
                Section {
                    TextField("Email (Optional)", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onChange(of: email) { _, _ in
                            emailError = isValidEmail(email) ? nil : "Please enter a valid email address"
                        }
                        .accessibilityLabel("Email field")
                    
                    TextField("Phone (Optional)", text: .init(
                        get: { phone },
                        set: { newValue in
                            // Only process if we're under 10 digits or deleting
                            let currentDigits = phone.filter { $0.isNumber }
                            let newDigits = newValue.filter { $0.isNumber }
                            
                            logger.debug("📱 Phone input - Current digits: \(currentDigits.count), New digits: \(newDigits.count)")
                            
                            if newDigits.count <= 10 || newValue.count < phone.count {
                                phone = formatPhoneNumber(newValue)
                                phoneError = isValidPhone(phone) ? nil : "Please enter a valid 10-digit phone number"
                            } else {
                                logger.notice("📱 Phone input - Blocked input beyond 10 digits")
                            }
                        }
                    ))
                    .keyboardType(.numberPad)
                    .accessibilityLabel("Phone field")
                    
                    if let error = phoneError {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    TextEditor(text: $request)
                        .frame(minHeight: 100)
                        .onChange(of: request) { _, _ in
                            requestError = request.isEmpty ? "Please enter your prayer request" : nil
                        }
                        .overlay(
                            Group {
                                if request.isEmpty {
                                    Text("Your Prayer Request Here")
                                        .foregroundColor(.gray)
                                        .padding(.leading, 5)
                                        .padding(.top, 8)
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
                        )
                    if let error = requestError {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Toggle("Keep Private", isOn: $isPrivate)
                    Toggle("Submit Anonymously", isOn: $isAnonymous)
                }
                
                Button(action: { Task { await submitRequest() } }) {
                    if isSubmitting {
                        ProgressView()
                            .controlSize(.regular)
                    } else {
                        Text("Submit")
                            .font(.headline)
                            .padding(.vertical, 8)
                    }
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .disabled(isSubmitting || (!isAnonymous && name.isEmpty) || !isValidEmail(email) || !isValidPhone(phone) || request.isEmpty)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
            .navigationTitle("Prayer Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSubmitting)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("Your prayer request has been submitted. We will pray for you.")
            }
        }
    }
    
    private func submitRequest() async {
        logger.notice("📝 Submitting prayer request")
        logger.debug("📱 Phone submission - Number: '\(phone)', Valid: \(isValidPhone(phone))")
        
        isSubmitting = true
        
        let request = PrayerRequest(
            id: UUID().uuidString,
            name: isAnonymous ? "Anonymous" : name,
            email: email,
            phone: phone,
            request: request,
            timestamp: Timestamp(date: Date()),
            status: .new,
            isPrivate: isPrivate,
            requestType: .personal
        )
        
        do {
            try await PrayerRequestService.shared.submitRequest(request)
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isSubmitting = false
    }
}

#Preview {
    PrayerRequestView()
}