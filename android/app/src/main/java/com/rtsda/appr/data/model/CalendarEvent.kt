package com.rtsda.appr.data.model

import com.google.firebase.Timestamp
import com.google.firebase.firestore.DocumentSnapshot
import java.util.Date

enum class RecurrenceType {
    NONE,
    DAILY,
    WEEKLY,
    BIWEEKLY,
    MONTHLY,
    FIRST_TUESDAY;

    companion object {
        fun fromString(value: String?): RecurrenceType {
            return try {
                valueOf(value?.uppercase() ?: NONE.name)
            } catch (e: IllegalArgumentException) {
                NONE
            }
        }
    }

    fun toDisplayString(): String {
        return when (this) {
            NONE -> "One-time"
            DAILY -> "Daily"
            WEEKLY -> "Weekly"
            BIWEEKLY -> "Bi-weekly"
            MONTHLY -> "Monthly"
            FIRST_TUESDAY -> "First Tuesday"
        }
    }
}

data class CalendarEvent(
    val id: String = "",
    val title: String = "",
    val description: String = "",
    val location: String = "",
    val startDate: Timestamp = Timestamp.now(),
    val endDate: Timestamp = Timestamp.now(),
    val recurrenceType: RecurrenceType = RecurrenceType.NONE,
    val parentEventId: String? = null,
    val isPublished: Boolean = false,
    val updatedAt: Timestamp = Timestamp.now()
) {
    // Convert Timestamp to Date for easier use in UI
    val startDateTime: Date
        get() = startDate.toDate()
    
    val endDateTime: Date
        get() = endDate.toDate()

    companion object {
        fun fromDocument(document: DocumentSnapshot): CalendarEvent? {
            return try {
                val data = document.data ?: return null
                
                // Handle both Timestamp and Double formats for dates
                val startDate = when (val startValue = data["startDate"]) {
                    is Timestamp -> startValue
                    is Double -> Timestamp(startValue.toLong(), 0)
                    else -> Timestamp.now()
                }
                
                val endDate = when (val endValue = data["endDate"]) {
                    is Timestamp -> endValue
                    is Double -> Timestamp(endValue.toLong(), 0)
                    else -> Timestamp.now()
                }
                
                val updatedAt = when (val updateValue = data["updatedAt"]) {
                    is Timestamp -> updateValue
                    is Double -> Timestamp(updateValue.toLong(), 0)
                    else -> Timestamp.now()
                }
                
                CalendarEvent(
                    id = document.id,
                    title = data["title"] as? String ?: "",
                    description = data["description"] as? String ?: "",
                    location = data["location"] as? String ?: "",
                    startDate = startDate,
                    endDate = endDate,
                    recurrenceType = RecurrenceType.fromString(data["recurrenceType"] as? String),
                    parentEventId = data["parentEventId"] as? String,
                    isPublished = data["isPublished"] as? Boolean ?: false,
                    updatedAt = updatedAt
                )
            } catch (e: Exception) {
                e.printStackTrace()
                null
            }
        }
    }

    fun toMap(): Map<String, Any> {
        return mapOf(
            "title" to title,
            "description" to description,
            "location" to location,
            "startDate" to startDate,
            "endDate" to endDate,
            "recurrenceType" to recurrenceType.name,
            "parentEventId" to (parentEventId ?: ""),
            "isPublished" to isPublished,
            "updatedAt" to updatedAt
        )
    }

    fun getNextOccurrence(): CalendarEvent {
        val calendar = java.util.Calendar.getInstance()
        calendar.time = startDate.toDate()
        
        when (recurrenceType) {
            RecurrenceType.DAILY -> calendar.add(java.util.Calendar.DAY_OF_YEAR, 1)
            RecurrenceType.WEEKLY -> calendar.add(java.util.Calendar.WEEK_OF_YEAR, 1)
            RecurrenceType.BIWEEKLY -> calendar.add(java.util.Calendar.WEEK_OF_YEAR, 2)
            RecurrenceType.MONTHLY -> calendar.add(java.util.Calendar.MONTH, 1)
            RecurrenceType.FIRST_TUESDAY -> {
                // Move to next month
                calendar.add(java.util.Calendar.MONTH, 1)
                // Set to first day of month
                calendar.set(java.util.Calendar.DAY_OF_MONTH, 1)
                // Find first Tuesday
                while (calendar.get(java.util.Calendar.DAY_OF_WEEK) != java.util.Calendar.TUESDAY) {
                    calendar.add(java.util.Calendar.DAY_OF_MONTH, 1)
                }
            }
            RecurrenceType.NONE -> return this
        }
        
        // Calculate the time difference between start and end dates
        val duration = endDate.seconds - startDate.seconds
        
        // Create new timestamps
        val newStartDate = Timestamp(calendar.time)
        val newEndDate = Timestamp(newStartDate.seconds + duration, newStartDate.nanoseconds)
        
        return copy(
            startDate = newStartDate,
            endDate = newEndDate,
            parentEventId = id // Preserve the parent event ID for recurring instances
        )
    }
}
