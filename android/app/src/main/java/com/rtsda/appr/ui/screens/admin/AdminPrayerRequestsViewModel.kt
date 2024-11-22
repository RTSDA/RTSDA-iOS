package com.rtsda.appr.ui.screens.admin

import android.net.ConnectivityManager
import android.net.Network
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.rtsda.appr.data.model.PrayerRequest
import com.rtsda.appr.data.model.RequestStatus
import com.rtsda.appr.data.model.RequestType
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

data class AdminPrayerRequestsUiState(
    val prayerRequests: List<PrayerRequest> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null,
    val selectedRequestType: RequestType = RequestType.ALL
)

@HiltViewModel
class AdminPrayerRequestsViewModel @Inject constructor(
    private val connectivityManager: ConnectivityManager,
    private val service: PrayerRequestService
) : ViewModel() {

    private val _uiState = MutableStateFlow(AdminPrayerRequestsUiState(isLoading = true))
    val uiState: StateFlow<AdminPrayerRequestsUiState> = _uiState.asStateFlow()

    private var networkCallback: ConnectivityManager.NetworkCallback? = null

    init {
        setupNetworkMonitoring()
        loadPrayerRequests()
    }

    private fun setupNetworkMonitoring() {
        networkCallback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                loadPrayerRequests()
            }

            override fun onLost(network: Network) {
                _uiState.value = _uiState.value.copy(
                    error = "Network connection lost"
                )
            }
        }

        connectivityManager.registerDefaultNetworkCallback(networkCallback!!)
    }

    fun loadPrayerRequests() {
        _uiState.value = _uiState.value.copy(isLoading = true)
        service.getPrayerRequests()
            .onEach { requests ->
                val filteredRequests = requests.filter { request ->
                    when (_uiState.value.selectedRequestType) {
                        RequestType.ALL -> true
                        RequestType.PERSONAL -> request.requestType == RequestType.PERSONAL
                        RequestType.FAMILY -> request.requestType == RequestType.FAMILY
                        RequestType.HEALTH -> request.requestType == RequestType.HEALTH
                        RequestType.FINANCIAL -> request.requestType == RequestType.FINANCIAL
                        RequestType.SPIRITUAL -> request.requestType == RequestType.SPIRITUAL
                        RequestType.OTHER -> request.requestType == RequestType.OTHER
                    }
                }
                _uiState.value = AdminPrayerRequestsUiState(
                    prayerRequests = filteredRequests.sortedByDescending { it.timestamp.seconds },
                    isLoading = false
                )
            }
            .catch { e ->
                Timber.e(e, "Error loading prayer requests")
                _uiState.value = AdminPrayerRequestsUiState(
                    isLoading = false,
                    error = e.message ?: "Error loading prayer requests"
                )
            }
            .launchIn(viewModelScope)
    }

    fun updateRequestStatus(request: PrayerRequest, status: RequestStatus) {
        viewModelScope.launch {
            try {
                service.updateStatus(request.id, status)
            } catch (e: Exception) {
                Timber.e(e, "Error updating prayer request status")
                _uiState.value = _uiState.value.copy(
                    error = "Failed to update prayer request: ${e.message}"
                )
            }
        }
    }

    fun deleteRequest(request: PrayerRequest) {
        viewModelScope.launch {
            try {
                service.deleteRequest(request.id)
            } catch (e: Exception) {
                Timber.e(e, "Error deleting prayer request")
                _uiState.value = _uiState.value.copy(
                    error = "Failed to delete prayer request: ${e.message}"
                )
            }
        }
    }

    fun updateSelectedRequestType(requestType: RequestType) {
        _uiState.value = _uiState.value.copy(selectedRequestType = requestType)
        loadPrayerRequests()
    }

    override fun onCleared() {
        super.onCleared()
        networkCallback?.let {
            connectivityManager.unregisterNetworkCallback(it)
        }
    }
}
