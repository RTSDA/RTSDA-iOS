import Foundation

struct AdminEventUiState {
    var events: [Event] = []
    var isLoading: Bool = false
    var error: String? = nil
}

struct EventValidationState {
    var hasStartDate: Bool = false
    var hasEndDate: Bool = false
    var hasTitle: Bool = false
    var hasLocation: Bool = false
    var isEndDateAfterStart: Bool = false
    
    var isValid: Bool {
        hasStartDate && hasEndDate && hasTitle && hasLocation && isEndDateAfterStart
    }
}
