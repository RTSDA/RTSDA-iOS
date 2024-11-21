import SwiftUI
import MessageUI

struct PrayerRequestView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.sizeCategory) private var sizeCategory
    @State private var name = ""
    @State private var email = ""
    @State private var requestType = PrayerRequest.RequestType.personal
    @State private var details = ""
    @State private var isConfidential = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false
    @State private var isSubmitting = false
    
    private let service = PrayerRequestService.shared
    
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
                    
                    TextField("Your Name", text: $name)
                        .font(.body)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                        .textContentType(.name)
                        .submitLabel(.next)
                        .accessibilityLabel("Name field")
                    
                    Toggle("Submit Anonymously", isOn: $isConfidential)
                        .accessibilityHint("Enable to submit your prayer request without your name")
                    
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .font(.body)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                        .accessibilityLabel("Email field")
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
                Text("Your prayer request has been submitted successfully.")
                    .font(.body)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility5)
            }
        }
    }
    
    private var isValidForm: Bool {
        !name.isEmpty && !email.isEmpty && !details.isEmpty
    }
    
    private func submitRequest() async {
        isSubmitting = true
        
        let request = PrayerRequest(
            id: UUID().uuidString,
            name: name,
            email: email,
            requestType: requestType,
            details: details,
            isConfidential: isConfidential,
            timestamp: Date(),
            prayedFor: false,
            prayedForDate: nil
        )
        
        do {
            let success = try await service.submitRequest(request)
            if success {
                showingSuccess = true
            } else {
                errorMessage = "Unable to submit request. Please try again."
                showingError = true
            }
        } catch {
            errorMessage = "An error occurred: \(error.localizedDescription)"
            showingError = true
        }
        
        isSubmitting = false
    }
}

#Preview {
    PrayerRequestView()
}