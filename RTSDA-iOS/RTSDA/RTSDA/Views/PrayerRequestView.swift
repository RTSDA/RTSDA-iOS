import SwiftUI

struct PrayerRequestView: View {
    @StateObject private var viewModel = PrayerRequestViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var requestType = ""
    @State private var request = ""
    @State private var isPrivate = false
    @State private var isAnonymous = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("We believe in the power of prayer. Share your prayer request with us, and our prayer team will lift your needs to God.")
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Section {
                    if !isAnonymous {
                        TextField("Name", text: $name)
                            .textContentType(.name)
                    }
                    
                    TextField("Email (Optional)", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    TextField("Phone (Optional)", text: $phone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }
                
                Section {
                    Picker("Type of Prayer Request", selection: $requestType) {
                        Text("Select a category").tag("")
                        ForEach(RequestType.allCases, id: \.rawValue) { type in
                            Text(type.rawValue).tag(type.rawValue)
                        }
                    }
                }
                
                Section(footer: Text("Private requests will only be shared with our prayer team.")) {
                    TextEditor(text: $request)
                        .frame(minHeight: 100)
                }
                
                Section {
                    if !isAnonymous {
                        Toggle("Keep Private", isOn: $isPrivate)
                    }
                    Toggle("Submit Anonymously", isOn: $isAnonymous)
                        .onChange(of: isAnonymous) { _, newValue in
                            isPrivate = newValue // Set private to match anonymous state
                        }
                }
                
                Section {
                    Button(action: {
                        Task {
                            await viewModel.submitPrayerRequest(
                                name: name,
                                email: email.isEmpty ? nil : email,
                                phone: phone.isEmpty ? nil : phone,
                                requestType: requestType,
                                request: request,
                                isPrivate: isPrivate,
                                isAnonymous: isAnonymous
                            )
                        }
                    }) {
                        if viewModel.isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Submit Prayer Request")
                        }
                    }
                    .disabled(viewModel.isSubmitting || 
                             (!isAnonymous && name.isEmpty) || 
                             requestType.isEmpty || 
                             request.isEmpty)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Prayer Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Prayer Request Submitted", isPresented: $viewModel.showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Thank you for sharing your prayer request. Our prayer team will be praying for you.")
            }
            .alert("Error", isPresented: $viewModel.showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
}
