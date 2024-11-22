package com.rtsda.appr.data.repository

import com.google.firebase.firestore.FirebaseFirestore
import com.rtsda.appr.data.model.CalendarEvent
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.tasks.await
import javax.inject.Inject
import javax.inject.Singleton

interface EventRepository {
    suspend fun getEvents(): Flow<List<CalendarEvent>>
    suspend fun deleteEvent(eventId: String)
}

@Singleton
class FirebaseEventRepository @Inject constructor(
    private val firestore: FirebaseFirestore
) : EventRepository {
    private val eventsFlow = MutableStateFlow<List<CalendarEvent>>(emptyList())
    private val eventsCollection = firestore.collection("events")

    init {
        setupEventsListener()
    }

    private fun setupEventsListener() {
        eventsCollection.addSnapshotListener { snapshot, error ->
            if (error != null) {
                return@addSnapshotListener
            }
            
            val events = snapshot?.documents?.mapNotNull { doc ->
                CalendarEvent.fromDocument(doc)
            } ?: emptyList()
            
            eventsFlow.value = events
        }
    }

    override suspend fun getEvents(): Flow<List<CalendarEvent>> = eventsFlow

    override suspend fun deleteEvent(eventId: String) {
        eventsCollection.document(eventId).delete().await()
    }
}
