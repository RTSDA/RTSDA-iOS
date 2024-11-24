package com.rtsda.appr.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import com.google.firebase.firestore.Query
import com.rtsda.appr.data.model.CalendarEvent
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import timber.log.Timber
import javax.inject.Inject

sealed class EventsError(val message: String) {
    class FetchFailed(message: String) : EventsError("Failed to fetch events: $message")
    class AddFailed(message: String) : EventsError("Failed to add event: $message")
    class UpdateFailed(message: String) : EventsError("Failed to update event: $message")
    class DeleteFailed(message: String) : EventsError("Failed to delete event: $message")
    class NetworkError(message: String) : EventsError("Network error: $message")
}

data class EventsUiState(
    val events: List<CalendarEvent> = emptyList(),
    val isLoading: Boolean = false,
    val error: EventsError? = null
)

@HiltViewModel
class EventsViewModel @Inject constructor(
    private val db: FirebaseFirestore
) : ViewModel() {

    private val _uiState = MutableStateFlow(EventsUiState(isLoading = true))
    val uiState: StateFlow<EventsUiState> = _uiState.asStateFlow()

    private var eventsListener: ListenerRegistration? = null

    init {
        setupEventsListener()
    }

    private fun setupEventsListener() {
        eventsListener?.remove()
        
        _uiState.update { it.copy(isLoading = true, error = null) }
        
        eventsListener = db.collection("events")
            .whereEqualTo("isPublished", true)
            .orderBy("startDate", Query.Direction.ASCENDING)
            .orderBy("id", Query.Direction.ASCENDING)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    Timber.e(error, "Error fetching events")
                    _uiState.update { 
                        it.copy(
                            isLoading = false,
                            error = EventsError.FetchFailed(error.message ?: "Unknown error")
                        )
                    }
                    return@addSnapshotListener
                }

                snapshot?.let { querySnapshot ->
                    try {
                        val events = querySnapshot.documents
                            .mapNotNull { doc ->
                                try {
                                    CalendarEvent.fromDocument(doc)?.takeIf { it.isPublished && !it.isDeleted }
                                } catch (e: Exception) {
                                    Timber.e(e, "Error parsing event ${doc.id}")
                                    null
                                }
                            }
                            .sortedBy { it.startDate.seconds }
                        
                        _uiState.update { 
                            it.copy(
                                events = events,
                                isLoading = false,
                                error = null
                            )
                        }
                    } catch (e: Exception) {
                        Timber.e(e, "Error processing events")
                        _uiState.update { 
                            it.copy(
                                isLoading = false,
                                error = EventsError.FetchFailed(e.message ?: "Unknown error")
                            )
                        }
                    }
                }
            }
    }

    fun loadEvents() {
        setupEventsListener()
    }

    fun refresh() {
        setupEventsListener()
    }

    suspend fun addEvent(event: CalendarEvent) {
        _uiState.update { it.copy(isLoading = true, error = null) }
        
        try {
            db.collection("events")
                .add(event.toMap())
                .await()
            
            _uiState.update { it.copy(isLoading = false) }
        } catch (e: Exception) {
            Timber.e(e, "Error adding event")
            _uiState.update { 
                it.copy(
                    isLoading = false,
                    error = EventsError.AddFailed(e.message ?: "Unknown error")
                )
            }
        }
    }

    override fun onCleared() {
        super.onCleared()
        eventsListener?.remove()
    }
}
