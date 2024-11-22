package com.rtsda.appr.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.rtsda.appr.data.model.PrayerRequest
import com.rtsda.appr.data.model.RequestStatus
import com.rtsda.appr.service.PrayerRequestService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

data class AdminPrayerRequestState(
    val isLoading: Boolean = false,
    val requests: List<PrayerRequest> = emptyList(),
    val error: String? = null
)

@HiltViewModel
class AdminPrayerRequestViewModel @Inject constructor() : ViewModel() {
    private val service = PrayerRequestService.getInstance()
    private val _state = MutableStateFlow(AdminPrayerRequestState(isLoading = true))
    val state: StateFlow<AdminPrayerRequestState> = _state.asStateFlow()

    init {
        loadPrayerRequests()
    }

    private fun loadPrayerRequests() {
        service.getPrayerRequests()
            .onEach { requests ->
                _state.value = AdminPrayerRequestState(
                    isLoading = false,
                    requests = requests
                )
            }
            .catch { e ->
                Timber.e(e, "Error loading prayer requests")
                _state.value = AdminPrayerRequestState(
                    isLoading = false,
                    error = e.message ?: "Error loading prayer requests"
                )
            }
            .launchIn(viewModelScope)
    }

    fun updateRequestStatus(requestId: String, status: RequestStatus) {
        viewModelScope.launch {
            try {
                service.updateStatus(requestId, status)
            } catch (e: Exception) {
                Timber.e(e, "Error updating prayer request status")
                // State will be automatically updated through the Flow
            }
        }
    }

    fun deleteRequest(requestId: String) {
        viewModelScope.launch {
            try {
                service.deleteRequest(requestId)
            } catch (e: Exception) {
                Timber.e(e, "Error deleting prayer request")
                // State will be automatically updated through the Flow
            }
        }
    }
}
