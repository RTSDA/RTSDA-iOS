package com.rtsda.appr.repositories

import android.util.Log
import com.google.firebase.Timestamp
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.Query
import com.rtsda.appr.models.Event
import kotlinx.coroutines.tasks.await
import java.util.*
import java.util.concurrent.TimeUnit

private const val TAG = "EventRepository"

class EventRepository {
    private val db = FirebaseFirestore.getInstance()
    private val eventsCollection = db.collection("events")

    init {
        // Update recurring events on initialization
        updateRecurringEvents()
    }

    private fun updateRecurringEvents() {
        try {
            Log.d(TAG, "Starting recurring events update...")
            val now = Timestamp.now()
            
            eventsCollection
                .whereNotEqualTo("recurrenceType", "NONE")
                .get()
                .addOnSuccessListener { snapshot ->
                    val events = snapshot.documents.mapNotNull { Event.fromDocument(it) }
                    Log.d(TAG, "Found recurring events: ${events.size}")
                    
                    events.forEach { event ->
                        // Only update if the event date has passed
                        if (event.startDate.seconds < now.seconds) {
                            calculateNextDate(event.startDate.toDate(), event.recurrenceType)?.let { nextDate ->
                                val duration = (event.endDate?.seconds ?: event.startDate.seconds) - event.startDate.seconds
                                val nextTimestamp = Timestamp(nextDate)
                                val endTimestamp = Timestamp(nextDate.time / 1000 + duration, 0)
                                
                                val updatedEvent = event.copy(
                                    startDate = nextTimestamp,
                                    endDate = endTimestamp
                                )
                                
                                eventsCollection.document(event.id)
                                    .set(updatedEvent.toMap())
                                    .addOnSuccessListener {
                                        Log.d(TAG, "Updated recurring event '${event.title}' to next occurrence: $nextDate")
                                    }
                                    .addOnFailureListener { e ->
                                        Log.e(TAG, "Error updating recurring event '${event.title}': $e")
                                    }
                            }
                        }
                    }
                }
                .addOnFailureListener { e ->
                    Log.e(TAG, "Error fetching recurring events: $e")
                }
        } catch (e: Exception) {
            Log.e(TAG, "Error in updateRecurringEvents: $e")
        }
    }

    private fun calculateNextDate(currentDate: Date, recurrenceType: String): Date? {
        val calendar = Calendar.getInstance().apply {
            time = currentDate
        }

        return when (recurrenceType.uppercase()) {
            "WEEKLY" -> {
                calendar.add(Calendar.WEEK_OF_YEAR, 1)
                calendar.time
            }
            "BIWEEKLY" -> {
                calendar.add(Calendar.WEEK_OF_YEAR, 2)
                calendar.time
            }
            "MONTHLY" -> {
                calendar.add(Calendar.MONTH, 1)
                calendar.time
            }
            "FIRST_TUESDAY" -> {
                // Move to next month
                calendar.add(Calendar.MONTH, 1)
                // Set to first day of month
                calendar.set(Calendar.DAY_OF_MONTH, 1)
                // Find first Tuesday
                while (calendar.get(Calendar.DAY_OF_WEEK) != Calendar.TUESDAY) {
                    calendar.add(Calendar.DAY_OF_MONTH, 1)
                }
                calendar.time
            }
            else -> null
        }
    }

    suspend fun getUpcomingEvents(): List<Event> {
        return try {
            val now = Timestamp.now()
            val snapshot = eventsCollection
                .whereGreaterThanOrEqualTo("startDate", now)
                .orderBy("startDate", Query.Direction.ASCENDING)
                .get()
                .await()

            snapshot.documents.mapNotNull { Event.fromDocument(it) }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting upcoming events", e)
            emptyList()
        }
    }

    suspend fun addEvent(event: Event): Boolean {
        return try {
            val now = Timestamp.now()
            val eventData = event.toMap().toMutableMap()

            // Ensure event is not in the past
            if (event.startDate.seconds < now.seconds) {
                eventData.apply {
                    put("startDate", now)
                    put("endDate", Timestamp(now.seconds + 3600, 0)) // 1 hour default
                }
            }

            eventsCollection.add(eventData).await()
            true
        } catch (e: Exception) {
            Log.e(TAG, "Error adding event", e)
            false
        }
    }

    suspend fun updateEvent(event: Event): Boolean {
        return try {
            eventsCollection.document(event.id)
                .set(event.toMap())
                .await()
            true
        } catch (e: Exception) {
            Log.e(TAG, "Error updating event", e)
            false
        }
    }

    suspend fun deleteEvent(eventId: String): Boolean {
        return try {
            eventsCollection.document(eventId)
                .delete()
                .await()
            true
        } catch (e: Exception) {
            Log.e(TAG, "Error deleting event", e)
            false
        }
    }
}
