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
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import timber.log.Timber
import javax.inject.Inject

@HiltViewModel
class EventsViewModel @Inject constructor(
    private val db: FirebaseFirestore
) : ViewModel() {

    private val _events = MutableStateFlow<List<CalendarEvent>>(emptyList())
    val events: StateFlow<List<CalendarEvent>> = _events.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private var eventsListener: ListenerRegistration? = null

    init {
        setupEventsListener()
    }

    private fun setupEventsListener() {
        eventsListener?.remove()
        
        eventsListener = db.collection("events")
            .whereEqualTo("isPublished", true)
            .orderBy("startDate", Query.Direction.ASCENDING)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    Timber.e(error, "Error fetching events")
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
                    }
                    Timber.d("Fetched ${events.size} events")
                    _events.value = events.sortedBy { it.startDate }
                }
            }
    }

    fun fetchEvents() {
        viewModelScope.launch {
            try {
                _isLoading.value = true
                val snapshot = db.collection("events")
                    .whereEqualTo("isPublished", true)
                    .orderBy("startDate", Query.Direction.ASCENDING)
                    .get()
                    .await()

                val events = snapshot.documents.mapNotNull { doc ->
                    try {
                        CalendarEvent.fromDocument(doc)?.also { event ->
                            Timber.d("Event ${event.id}: published=${event.isPublished}")
                        }
                    } catch (e: Exception) {
                        Timber.e(e, "Error parsing event ${doc.id}")
                        null
                    }
                }
                Timber.d("Fetched ${events.size} events")
                _events.value = events.sortedBy { it.startDate }
            } catch (e: Exception) {
                Timber.e(e, "Error fetching events")
            } finally {
                _isLoading.value = false
            }
        }
    }

    override fun onCleared() {
        super.onCleared()
        eventsListener?.remove()
    }
}
