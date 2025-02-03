import SwiftUI
import AVKit

struct MessagesView: View {
    @StateObject private var viewModel = MessagesViewModel()
    @State private var selectedYear: String?
    @State private var selectedMonth: String?
    @State private var showingFilters = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header with Filter Button and Active Filters
                VStack(spacing: 8) {
                    HStack {
                        Button {
                            showingFilters = true
                        } label: {
                            HStack {
                                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                Text("Filter")
                            }
                            .font(.headline)
                            .foregroundStyle(.blue)
                        }
                        
                        Spacer()
                        
                        if selectedYear != nil || selectedMonth != nil {
                            Button(action: {
                                selectedYear = nil
                                selectedMonth = nil
                                viewModel.filterContent(year: nil, month: nil)
                            }) {
                                Text("Clear Filters")
                                    .foregroundStyle(.red)
                                    .font(.subheadline)
                            }
                        }
                    }
                    
                    // Active Filters Display
                    if selectedYear != nil || selectedMonth != nil || viewModel.currentMediaType == .livestreams {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                // Media Type Pill
                                Text(viewModel.currentMediaType == .sermons ? "Sermons" : "Live Archives")
                                    .font(.footnote.weight(.medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundStyle(.blue)
                                    .clipShape(Capsule())
                                
                                // Year Pill (if selected)
                                if let year = selectedYear {
                                    Text(year)
                                        .font(.footnote.weight(.medium))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundStyle(.blue)
                                        .clipShape(Capsule())
                                }
                                
                                // Month Pill (if selected)
                                if let month = selectedMonth {
                                    Text(formatMonth(month))
                                        .font(.footnote.weight(.medium))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundStyle(.blue)
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Content Section
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else if viewModel.error != nil {
                    VStack {
                        Text("Error loading content")
                            .foregroundColor(.red)
                        Button("Try Again") {
                            Task {
                                await viewModel.refreshContent()
                            }
                        }
                    }
                    .padding()
                } else if viewModel.filteredMessages.isEmpty {
                    Text("No messages available")
                        .padding()
                } else {
                    LazyVStack(spacing: 16) {
                        if let livestream = viewModel.livestream {
                            MessageCard(message: livestream)
                                .padding(.horizontal)
                        }
                        
                        ForEach(viewModel.filteredMessages) { message in
                            MessageCard(message: message)
                                .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .navigationTitle(viewModel.currentMediaType == .sermons ? "Sermons" : "Live Archives")
        .refreshable {
            await viewModel.refreshContent()
        }
        .sheet(isPresented: $showingFilters) {
            NavigationStack {
                FilterView(
                    currentMediaType: $viewModel.currentMediaType,
                    selectedYear: $selectedYear,
                    selectedMonth: $selectedMonth,
                    availableYears: viewModel.availableYears,
                    availableMonths: viewModel.availableMonths,
                    onMediaTypeChange: { newType in
                        Task {
                            await viewModel.loadContent(mediaType: newType)
                        }
                    },
                    onYearChange: { year in
                        if let year = year {
                            viewModel.updateMonthsForYear(year)
                        }
                        viewModel.filterContent(year: year, month: selectedMonth)
                    },
                    onMonthChange: { month in
                        viewModel.filterContent(year: selectedYear, month: month)
                    }
                )
                .navigationTitle("Filter Content")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Done") {
                            showingFilters = false
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        if selectedYear != nil || selectedMonth != nil {
                            Button("Reset") {
                                selectedYear = nil
                                selectedMonth = nil
                                viewModel.filterContent(year: nil, month: nil)
                                showingFilters = false
                            }
                            .foregroundStyle(.red)
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
    
    private func formatMonth(_ month: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM"
        
        if let date = formatter.date(from: month) {
            formatter.dateFormat = "MMM"
            return formatter.string(from: date)
        }
        return month
    }
}

struct FilterView: View {
    @Binding var currentMediaType: JellyfinService.MediaType
    @Binding var selectedYear: String?
    @Binding var selectedMonth: String?
    let availableYears: [String]
    let availableMonths: [String]
    let onMediaTypeChange: (JellyfinService.MediaType) -> Void
    let onYearChange: (String?) -> Void
    let onMonthChange: (String?) -> Void
    
    var body: some View {
        Form {
            Section("Content Type") {
                Picker("Type", selection: $currentMediaType) {
                    Text("Sermons").tag(JellyfinService.MediaType.sermons)
                    Text("Live Archives").tag(JellyfinService.MediaType.livestreams)
                }
                .pickerStyle(.segmented)
                .onChange(of: currentMediaType) { oldValue, newValue in
                    selectedYear = nil
                    selectedMonth = nil
                    onMediaTypeChange(newValue)
                }
            }
            
            Section("Year") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        MessageFilterChip(
                            title: "All",
                            isSelected: selectedYear == nil,
                            action: {
                                selectedYear = nil
                                selectedMonth = nil
                                onYearChange(nil)
                            }
                        )
                        
                        ForEach(availableYears, id: \.self) { year in
                            MessageFilterChip(
                                title: year,
                                isSelected: selectedYear == year,
                                action: {
                                    selectedYear = year
                                    selectedMonth = nil
                                    onYearChange(year)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            if selectedYear != nil && !availableMonths.isEmpty {
                Section("Month") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            MessageFilterChip(
                                title: "All",
                                isSelected: selectedMonth == nil,
                                action: {
                                    selectedMonth = nil
                                    onMonthChange(nil)
                                }
                            )
                            
                            ForEach(availableMonths, id: \.self) { month in
                                MessageFilterChip(
                                    title: formatMonth(month),
                                    isSelected: selectedMonth == month,
                                    action: {
                                        selectedMonth = month
                                        onMonthChange(month)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
            }
        }
    }
    
    private func formatMonth(_ month: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM"
        
        if let date = formatter.date(from: month) {
            formatter.dateFormat = "MMM"
            return formatter.string(from: date)
        }
        return month
    }
}

struct MessageFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.15))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

// Helper extension for optional binding in Picker
extension Binding where Value == String? {
    func toUnwrapped(defaultValue: String) -> Binding<String> {
        Binding<String>(
            get: { self.wrappedValue ?? defaultValue },
            set: { self.wrappedValue = $0 }
        )
    }
} 
