package com.rtsda.appr.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.google.firebase.Timestamp
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject
import com.rtsda.appr.data.model.PrayerRequest
import com.rtsda.appr.data.model.RequestStatus
import com.rtsda.appr.data.model.RequestType
import com.rtsda.appr.service.PrayerRequestService

data class PrayerRequestState(
    val isLoading: Boolean = false,
    val isSuccess: Boolean = false,
    val error: String? = null
)

@HiltViewModel
class PrayerRequestViewModel @Inject constructor() : ViewModel() {

    private val service = PrayerRequestService.getInstance()
    private val _state = MutableStateFlow(PrayerRequestState())
    val state: StateFlow<PrayerRequestState> = _state.asStateFlow()

    fun submitPrayerRequest(
        name: String,
        email: String,
        phone: String,
        request: String,
        isPrivate: Boolean = false,
        requestType: RequestType = RequestType.PERSONAL
    ) {
        viewModelScope.launch {
            try {
                _state.value = PrayerRequestState(isLoading = true)
                
                val prayerRequest = PrayerRequest(
                    name = name,
                    email = email,
                    phone = phone,
                    request = request,
                    timestamp = Timestamp.now(),
                    status = RequestStatus.NEW,
                    isPrivate = isPrivate,
                    requestType = requestType
                )
                
                val success = service.submitRequest(prayerRequest)
                
                _state.value = if (success) {
                    PrayerRequestState(isSuccess = true)
                } else {
                    PrayerRequestState(error = "Failed to submit prayer request")
                }
            } catch (e: Exception) {
                Timber.e(e, "Error submitting prayer request")
                _state.value = PrayerRequestState(error = e.message ?: "Unknown error occurred")
            }
        }
    }
    
    fun resetState() {
        _state.value = PrayerRequestState()
    }
}
