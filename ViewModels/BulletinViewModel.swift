import Foundation
import SwiftUI

@MainActor
class BulletinViewModel: ObservableObject {
    @Published var latestBulletin: Bulletin?
    @Published var bulletins: [Bulletin] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let pocketBaseService = PocketBaseService.shared
    private var currentTask: Task<Void, Never>?
    
    func loadLatestBulletin() async {
        // Cancel any existing task
        currentTask?.cancel()
        
        // Create new task
        currentTask = Task {
            guard !Task.isCancelled else { return }
            
            isLoading = true
            error = nil
            
            do {
                let response = try await pocketBaseService.fetchBulletins(activeOnly: true)
                if !Task.isCancelled {
                    if let bulletin = response.items.first {
                        print("Loaded bulletin with ID: \(bulletin.id)")
                        print("PDF field value: \(bulletin.pdf ?? "nil")")
                        print("Generated PDF URL: \(bulletin.pdfUrl)")
                        latestBulletin = bulletin
                    }
                }
            } catch {
                if !Task.isCancelled {
                    print("Error loading bulletin: \(error)")
                    self.error = error
                }
            }
            
            if !Task.isCancelled {
                isLoading = false
            }
        }
        
        // Wait for the task to complete
        await currentTask?.value
    }
    
    @MainActor
    func loadBulletins() async {
        // Cancel any existing task
        currentTask?.cancel()
        
        // Create new task
        currentTask = Task {
            guard !Task.isCancelled else { return }
            
            isLoading = true
            error = nil
            
            do {
                let response = try await PocketBaseService.shared.fetchBulletins(activeOnly: true)
                if !Task.isCancelled {
                    self.bulletins = response.items
                }
            } catch {
                if !Task.isCancelled {
                    print("Error loading bulletins: \(error)")
                    self.error = error
                }
            }
            
            if !Task.isCancelled {
                isLoading = false
            }
        }
        
        // Wait for the task to complete
        await currentTask?.value
    }
    
    deinit {
        currentTask?.cancel()
    }
} 
