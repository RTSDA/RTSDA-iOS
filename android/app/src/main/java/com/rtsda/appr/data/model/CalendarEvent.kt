package com.rtsda.appr.data.model

import com.google.firebase.Timestamp
import com.google.firebase.firestore.DocumentSnapshot
import java.util.Date
import java.text.SimpleDateFormat
import java.util.Locale

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
    val locationUrl: String? = null,
    val startDate: Timestamp = Timestamp.now(),
    val endDate: Timestamp? = null,
    val recurrenceType: RecurrenceType = RecurrenceType.NONE,
    val parentEventId: String? = null,
    val createdAt: Timestamp? = null,
    val updatedAt: Timestamp? = null,
    val createdBy: String? = null,
    val updatedBy: String? = null,
    val isPublished: Boolean = false,
    val isDeleted: Boolean = false
) {
    // Convert Timestamp to Date for easier use in UI
    val startDateTime: Date
        get() = startDate.toDate()
    
    val endDateTime: Date?
        get() = endDate?.toDate()
    
    val formattedStartDate: String
        get() {
            val formatter = SimpleDateFormat("MMM d, yyyy h:mm a", Locale.getDefault())
            return formatter.format(startDateTime)
        }

    fun nextOccurrence(): CalendarEvent? {
        if (recurrenceType == RecurrenceType.NONE) return null
        
        val calendar = java.util.Calendar.getInstance()
        var nextStart = startDateTime
        val now = Date()
        
        // Keep incrementing until we find a future date
        while (nextStart <= now) {
            calendar.time = nextStart
            when (recurrenceType) {
                RecurrenceType.DAILY -> calendar.add(java.util.Calendar.DAY_OF_YEAR, 1)
                RecurrenceType.WEEKLY -> calendar.add(java.util.Calendar.WEEK_OF_YEAR, 1)
                RecurrenceType.BIWEEKLY -> calendar.add(java.util.Calendar.WEEK_OF_YEAR, 2)
                RecurrenceType.MONTHLY -> calendar.add(java.util.Calendar.MONTH, 1)
                RecurrenceType.FIRST_TUESDAY -> {
                    calendar.add(java.util.Calendar.MONTH, 1)
                    calendar.set(java.util.Calendar.DAY_OF_WEEK, java.util.Calendar.TUESDAY)
                    calendar.set(java.util.Calendar.DAY_OF_WEEK_IN_MONTH, 1)
                }
                RecurrenceType.NONE -> return null
            }
            nextStart = calendar.time
        }
        
        return copy(
            id = "",
            startDate = Timestamp(nextStart),
            endDate = endDate?.let { 
                val diff = it.seconds - startDate.seconds
                Timestamp(nextStart.time / 1000 + diff, 0)
            },
            parentEventId = id
        )
    }

    companion object {
        fun fromDocument(document: DocumentSnapshot): CalendarEvent? {
            return try {
                val data = document.data ?: return null
                
                fun parseTimestamp(value: Any?): Timestamp? = when (value) {
                    is Timestamp -> value
                    is Double -> Timestamp(value.toLong(), 0)
                    else -> null
                }
                
                CalendarEvent(
                    id = document.id,
                    title = data["title"] as? String ?: "",
                    description = data["description"] as? String ?: "",
                    location = data["location"] as? String ?: "",
                    locationUrl = data["locationUrl"] as? String,
                    startDate = parseTimestamp(data["startDate"]) ?: Timestamp.now(),
                    endDate = parseTimestamp(data["endDate"]),
                    recurrenceType = RecurrenceType.fromString(data["recurrenceType"] as? String),
                    parentEventId = data["parentEventId"] as? String,
                    createdAt = parseTimestamp(data["createdAt"]),
                    updatedAt = parseTimestamp(data["updatedAt"]),
                    createdBy = data["createdBy"] as? String,
                    updatedBy = data["updatedBy"] as? String,
                    isPublished = data["isPublished"] as? Boolean ?: false,
                    isDeleted = data["isDeleted"] as? Boolean ?: false
                )
            } catch (e: Exception) {
                e.printStackTrace()
                null
            }
        }
    }

    fun toMap(): Map<String, Any> {
        return buildMap {
            put("title", title)
            put("description", description)
            put("location", location)
            locationUrl?.let { put("locationUrl", it) }
            put("startDate", startDate)
            endDate?.let { put("endDate", it) }
            put("recurrenceType", recurrenceType.name)
            parentEventId?.let { put("parentEventId", it) }
            createdAt?.let { put("createdAt", it) }
            updatedAt?.let { put("updatedAt", it) }
            createdBy?.let { put("createdBy", it) }
            updatedBy?.let { put("updatedBy", it) }
            put("isPublished", isPublished)
            put("isDeleted", isDeleted)
        }
    }
}
