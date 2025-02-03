import Foundation
import AVKit

@MainActor
class SermonBrowserViewModel: ObservableObject {
    @Published private(set) var sermons: [Sermon] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published var selectedType: SermonType = .sermon
    @Published var selectedYear: Int?
    @Published var selectedMonth: Int?
    
    let jellyfinService: JellyfinService
    
    var organizedSermons: [Int: [Int: [Sermon]]] {
        var filteredSermons = sermons.filter { $0.type == selectedType }
        
        // Apply year filter if selected
        if let selectedYear = selectedYear {
            filteredSermons = filteredSermons.filter {
                Calendar.current.component(.year, from: $0.date) == selectedYear
            }
        }
        
        // Apply month filter if selected
        if let selectedMonth = selectedMonth {
            filteredSermons = filteredSermons.filter {
                Calendar.current.component(.month, from: $0.date) == selectedMonth
            }
        }
        
        return Dictionary(grouping: filteredSermons) { sermon in
            Calendar.current.component(.year, from: sermon.date)
        }.mapValues { yearSermons in
            Dictionary(grouping: yearSermons) { sermon in
                Calendar.current.component(.month, from: sermon.date)
            }
        }
    }
    
    var years: [Int] {
        let filteredSermons = sermons.filter { $0.type == selectedType }
        let allYears = Set(filteredSermons.map {
            Calendar.current.component(.year, from: $0.date)
        })
        return Array(allYears).sorted(by: >)
    }
    
    func months(for year: Int) -> [Int] {
        let yearSermons = sermons.filter {
            $0.type == selectedType &&
            Calendar.current.component(.year, from: $0.date) == year
        }
        return Array(Set(yearSermons.map {
            Calendar.current.component(.month, from: $0.date)
        })).sorted(by: >)
    }
    
    func sermons(for year: Int, month: Int) -> [Sermon] {
        organizedSermons[year]?[month]?.sorted(by: { $0.date > $1.date }) ?? []
    }
    
    @MainActor
    init(jellyfinService: JellyfinService) {
        self.jellyfinService = jellyfinService
    }
    
    @MainActor
    convenience init() {
        self.init(jellyfinService: JellyfinService.shared)
    }
    
    @MainActor
    func fetchSermons() async throws {
        isLoading = true
        error = nil
        
        do {
            sermons = try await jellyfinService.fetchSermons(type: .sermon)
            
            if let firstYear = years.first {
                selectedYear = firstYear
                if let firstMonth = months(for: firstYear).first {
                    selectedMonth = firstMonth
                }
            }
        } catch {
            self.error = error
            throw error
        }
        
        isLoading = false
    }
    
    func selectType(_ type: SermonType) {
        selectedType = type
        selectedYear = nil
        selectedMonth = nil
        
        if let firstYear = years.first {
            selectedYear = firstYear
            if let firstMonth = months(for: firstYear).first {
                selectedMonth = firstMonth
            }
        }
    }
    
    func selectYear(_ year: Int?) {
        selectedYear = year
        selectedMonth = nil
        
        if let year = year,
           let firstMonth = months(for: year).first {
            selectedMonth = firstMonth
        }
    }
    
    func selectMonth(_ month: Int?) {
        selectedMonth = month
    }
    
    @MainActor
    func loadSermons() async {
        isLoading = true
        error = nil
        
        do {
            sermons = try await jellyfinService.fetchSermons(type: .sermon)
            
            if let firstYear = years.first {
                selectedYear = firstYear
                if let firstMonth = months(for: firstYear).first {
                    selectedMonth = firstMonth
                }
            }
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    @MainActor
    func requestPermissions() async {
        let permissionsManager = PermissionsManager.shared
        permissionsManager.requestLocationAccess()
    }
} 
