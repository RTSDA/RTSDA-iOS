package com.rtsda.appr.ui.screens.admin

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.ktx.firestore
import com.google.firebase.ktx.Firebase
import com.rtsda.appr.data.model.PrayerRequest
import com.rtsda.appr.data.model.RequestStatus
import com.rtsda.appr.data.model.RequestType
import com.rtsda.appr.service.PrayerRequestService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import timber.log.Timber
import javax.inject.Inject

data class AdminPrayerRequestsUiState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val prayerRequests: List<PrayerRequest> = emptyList(),
    val filteredRequests: List<PrayerRequest> = emptyList(),
    val selectedRequestType: RequestType = RequestType.ALL,
    val showApprovedOnly: Boolean = false,
    val showPrivateOnly: Boolean = false,
    val showAnonymousOnly: Boolean = false,
    val searchText: String = ""
)

@HiltViewModel
class AdminPrayerRequestsViewModel @Inject constructor(
    private val prayerRequestService: PrayerRequestService,
    private val auth: FirebaseAuth
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(AdminPrayerRequestsUiState())
    val uiState: StateFlow<AdminPrayerRequestsUiState> = _uiState.asStateFlow()
    
    init {
        loadPrayerRequests()
    }
    
    fun loadPrayerRequests() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            
            try {
                val currentUser = auth.currentUser
                if (currentUser == null) {
                    throw IllegalStateException("User must be authenticated for admin access")
                }
                
                val adminDoc = auth.currentUser?.let { user ->
                    Firebase.firestore
                        .collection("admins")
                        .document(user.uid)
                        .get()
                        .await()
                }
                
                if (adminDoc?.exists() != true) {
                    throw IllegalStateException("User does not have admin privileges")
                }
                
                // Now start collecting prayer requests
                prayerRequestService.getPrayerRequests()
                    .catch { e ->
                        Timber.e(e, "Error loading prayer requests")
                        _uiState.update { 
                            it.copy(
                                isLoading = false,
                                error = e.message ?: "Failed to load prayer requests"
                            )
                        }
                    }
                    .collect { requests ->
                        _uiState.update { state -> 
                            state.copy(
                                isLoading = false,
                                prayerRequests = requests,
                                filteredRequests = filterRequests(state, requests)
                            )
                        }
                    }
                    
            } catch (e: Exception) {
                Timber.e(e, "Error in admin authentication")
                _uiState.update { 
                    it.copy(
                        isLoading = false,
                        error = e.message ?: "Failed to authenticate as admin"
                    )
                }
            }
        }
    }
    
    private fun filterRequests(state: AdminPrayerRequestsUiState, requests: List<PrayerRequest>): List<PrayerRequest> {
        return requests.filter { request ->
            val matchesType = state.selectedRequestType == RequestType.ALL || 
                request.requestType == state.selectedRequestType
                
            val matchesApprovedFilter = !state.showApprovedOnly || 
                request.status == RequestStatus.APPROVED
                
            val matchesPrivateFilter = !state.showPrivateOnly || 
                request.isPrivate
                
            val matchesAnonymousFilter = !state.showAnonymousOnly || 
                request.isAnonymous
                
            val matchesSearch = state.searchText.isEmpty() || 
                request.request.contains(state.searchText, ignoreCase = true) ||
                (!request.isAnonymous && request.name.contains(state.searchText, ignoreCase = true))
                
            matchesType && matchesApprovedFilter && matchesPrivateFilter && 
                matchesAnonymousFilter && matchesSearch
        }
    }
    
    fun updateFilters(
        selectedType: RequestType,
        showApprovedOnly: Boolean,
        showPrivateOnly: Boolean,
        showAnonymousOnly: Boolean,
        searchText: String
    ) {
        _uiState.update { state ->
            state.copy(
                selectedRequestType = selectedType,
                showApprovedOnly = showApprovedOnly,
                showPrivateOnly = showPrivateOnly,
                showAnonymousOnly = showAnonymousOnly,
                searchText = searchText,
                filteredRequests = filterRequests(
                    state.copy(
                        selectedRequestType = selectedType,
                        showApprovedOnly = showApprovedOnly,
                        showPrivateOnly = showPrivateOnly,
                        showAnonymousOnly = showAnonymousOnly,
                        searchText = searchText
                    ),
                    state.prayerRequests
                )
            )
        }
    }
    
    fun updatePrayerRequestStatus(requestId: String, newStatus: RequestStatus) {
        viewModelScope.launch {
            try {
                prayerRequestService.updatePrayerRequestStatus(requestId, newStatus)
            } catch (e: Exception) {
                Timber.e(e, "Error updating prayer request status")
                _uiState.update { 
                    it.copy(error = e.message ?: "Failed to update prayer request status")
                }
            }
        }
    }
    
    fun deletePrayerRequest(request: PrayerRequest) {
        viewModelScope.launch {
            try {
                prayerRequestService.deletePrayerRequest(request.id)
            } catch (e: Exception) {
                Timber.e(e, "Error deleting prayer request")
                _uiState.update { 
                    it.copy(error = e.message ?: "Failed to delete prayer request")
                }
            }
        }
    }
}
