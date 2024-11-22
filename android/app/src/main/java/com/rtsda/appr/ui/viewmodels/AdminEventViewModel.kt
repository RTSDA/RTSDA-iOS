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

data class AdminEventUiState(
    val events: List<CalendarEvent> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null,
    val eventToEdit: CalendarEvent? = null
)

@HiltViewModel
class AdminEventViewModel @Inject constructor(
    private val db: FirebaseFirestore
) : ViewModel() {

    private val _uiState = MutableStateFlow(AdminEventUiState())
    val uiState: StateFlow<AdminEventUiState> = _uiState.asStateFlow()

    private var eventsListener: ListenerRegistration? = null

    init {
        setupEventsListener()
    }

    fun refreshEvents() {
        _uiState.update { it.copy(isLoading = true) }
        setupEventsListener()
    }

    private fun setupEventsListener() {
        eventsListener?.remove()

        eventsListener = db.collection("events")
            .orderBy("startDate", Query.Direction.ASCENDING)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    Timber.e(error, "Error fetching events")
                    _uiState.update { 
                        it.copy(
                            error = error.localizedMessage,
                            isLoading = false
                        )
                    }
                    return@addSnapshotListener
                }

                snapshot?.let { querySnapshot ->
                    val events = querySnapshot.documents.mapNotNull { doc ->
                        try {
                            CalendarEvent.fromDocument(doc)?.also { event ->
                                Timber.d("Event ${event.id}: published=${event.isPublished}")
                            }
                        } catch (e: Exception) {
                            Timber.e(e, "Error parsing event ${doc.id}")
                            null
                        }
                    }.sortedBy { it.startDate }
                    _uiState.update { 
                        it.copy(
                            events = events,
                            isLoading = false,
                            error = null
                        )
                    }
                    Timber.d("Updated events list with ${events.size} events")
                }
            }
    }

    fun deleteEvent(event: CalendarEvent) {
        viewModelScope.launch {
            try {
                db.collection("events")
                    .document(event.id)
                    .delete()
                    .await()
            } catch (e: Exception) {
                Timber.e(e, "Error deleting event")
                _uiState.update { it.copy(error = e.localizedMessage) }
            }
        }
    }

    fun publishEvent(event: CalendarEvent) {
        viewModelScope.launch {
            try {
                db.collection("events")
                    .document(event.id)
                    .update(mapOf(
                        "isPublished" to true,
                        "updatedAt" to com.google.firebase.Timestamp.now()
                    ))
                    .await()
            } catch (e: Exception) {
                Timber.e(e, "Error publishing event")
                _uiState.update { it.copy(error = e.localizedMessage) }
            }
        }
    }

    fun unpublishEvent(event: CalendarEvent) {
        viewModelScope.launch {
            try {
                Timber.d("Attempting to unpublish event ${event.id}")
                db.collection("events")
                    .document(event.id)
                    .update(mapOf(
                        "isPublished" to false,
                        "updatedAt" to com.google.firebase.Timestamp.now()
                    ))
                    .await()
                Timber.d("Successfully unpublished event ${event.id}")
            } catch (e: Exception) {
                Timber.e(e, "Error unpublishing event ${event.id}")
                _uiState.update { it.copy(error = e.localizedMessage) }
            }
        }
    }

    fun loadEvent(eventId: String) {
        viewModelScope.launch {
            try {
                _uiState.update { it.copy(isLoading = true, error = null) }
                val doc = db.collection("events")
                    .document(eventId)
                    .get()
                    .await()
                
                val event = CalendarEvent.fromDocument(doc)
                if (event != null) {
                    _uiState.update { it.copy(eventToEdit = event, isLoading = false) }
                } else {
                    _uiState.update { it.copy(
                        error = "Event not found",
                        isLoading = false
                    ) }
                }
            } catch (e: Exception) {
                Timber.e(e, "Error loading event")
                _uiState.update { it.copy(
                    error = e.localizedMessage,
                    isLoading = false
                ) }
            }
        }
    }

    fun addEvent(event: CalendarEvent) {
        viewModelScope.launch {
            try {
                _uiState.update { it.copy(isLoading = true, error = null) }
                val newEvent = event.copy(
                    id = db.collection("events").document().id,
                    updatedAt = com.google.firebase.Timestamp.now()
                )
                db.collection("events")
                    .document(newEvent.id)
                    .set(newEvent.toMap())
                    .await()
                
                // Refresh the events list
                refreshEvents()
            } catch (e: Exception) {
                Timber.e(e, "Error adding event")
                _uiState.update { it.copy(
                    error = e.localizedMessage,
                    isLoading = false
                ) }
            }
        }
    }

    fun updateEvent(event: CalendarEvent) {
        viewModelScope.launch {
            try {
                _uiState.update { it.copy(isLoading = true, error = null) }
                val updatedEvent = event.copy(
                    updatedAt = com.google.firebase.Timestamp.now()
                )
                db.collection("events")
                    .document(event.id)
                    .set(updatedEvent.toMap())
                    .await()
                
                // Refresh the events list
                refreshEvents()
            } catch (e: Exception) {
                Timber.e(e, "Error updating event")
                _uiState.update { it.copy(
                    error = e.localizedMessage,
                    isLoading = false
                ) }
            }
        }
    }

    fun clearCache() {
        _uiState.update { it.copy(
            eventToEdit = null,
            error = null
        ) }
    }

    override fun onCleared() {
        super.onCleared()
        eventsListener?.remove()
    }
}
