import SwiftUI
import SafariServices

struct MoreView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    ConnectView()
                } label: {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.blue)
                        Text("Contact & Connect")
                    }
                }
                
                NavigationLink {
                    ResourcesView()
                } label: {
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.blue)
                        Text("Resources")
                    }
                }
                
                NavigationLink {
                    AdminLoginView()
                } label: {
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.blue)
                        Text("Admin")
                    }
                }
            }
            .navigationTitle("More")
        }
    }
}

struct ContactView: View {
    var body: some View {
        List {
            Link(destination: URL(string: "tel:8608751785")!) {
                HStack {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.blue)
                    Text("Call Us")
                }
            }
            
            Link(destination: URL(string: "mailto:info@rockvilletollandsda.org")!) {
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.blue)
                    Text("Email Us")
                }
            }
            
            Link(destination: URL(string: "https://www.facebook.com/RockvilleTollandSDA")!) {
                HStack {
                    Image(systemName: "link")
                        .foregroundColor(.blue)
                    Text("Facebook")
                }
            }
        }
        .navigationTitle("Contact & Connect")
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

#Preview {
    MoreView()
}