package com.rtsda.appr.models

import com.google.firebase.Timestamp
import com.google.firebase.firestore.DocumentSnapshot
import com.google.firebase.firestore.PropertyName
import java.util.*

data class Event(
    val id: String = "",
    val title: String = "",
    val description: String = "",
    @get:PropertyName("startDate")
    @set:PropertyName("startDate")
    var startDate: Timestamp = Timestamp.now(),
    @get:PropertyName("endDate")
    @set:PropertyName("endDate")
    var endDate: Timestamp? = null,
    val location: String = "",
    val locationUrl: String? = null,
    @get:PropertyName("recurrenceType")
    @set:PropertyName("recurrenceType")
    var recurrenceType: String = "NONE",
    val parentEventId: String? = null,
    @get:PropertyName("isPublished")
    @set:PropertyName("isPublished")
    var isPublished: Boolean = false,
    @get:PropertyName("updatedAt")
    @set:PropertyName("updatedAt")
    var updatedAt: Timestamp = Timestamp.now()
) {
    companion object {
        fun fromDocument(document: DocumentSnapshot): Event? {
            return try {
                val data = document.data ?: return null
                
                val startDate = when (val startVal = data["startDate"]) {
                    is Timestamp -> startVal
                    is Double -> Timestamp(startVal.toLong(), 0)
                    is Long -> Timestamp(startVal, 0)
                    else -> Timestamp.now()
                }
                
                val endDate = when (val endVal = data["endDate"]) {
                    is Timestamp -> endVal
                    is Double -> Timestamp(endVal.toLong(), 0)
                    is Long -> Timestamp(endVal, 0)
                    else -> null
                }
                
                val updatedAt = when (val updateVal = data["updatedAt"]) {
                    is Timestamp -> updateVal
                    is Double -> Timestamp(updateVal.toLong(), 0)
                    is Long -> Timestamp(updateVal, 0)
                    else -> Timestamp.now()
                }
                
                Event(
                    id = document.id,
                    title = data["title"] as? String ?: "",
                    description = data["description"] as? String ?: "",
                    startDate = startDate,
                    endDate = endDate,
                    location = data["location"] as? String ?: "",
                    locationUrl = data["locationUrl"] as? String,
                    recurrenceType = (data["recurrenceType"] as? String ?: "NONE").uppercase(),
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

    fun toMap(): Map<String, Any?> {
        return mapOf(
            "title" to title,
            "description" to description,
            "startDate" to startDate,
            "endDate" to endDate,
            "location" to location,
            "locationUrl" to locationUrl,
            "recurrenceType" to recurrenceType,
            "parentEventId" to parentEventId,
            "isPublished" to isPublished,
            "updatedAt" to updatedAt
        )
    }

    val startDateTime: Date
        get() = startDate.toDate()

    val endDateTime: Date?
        get() = endDate?.toDate()
}
