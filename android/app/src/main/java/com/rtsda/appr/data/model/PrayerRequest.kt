package com.rtsda.appr.data.model

import com.google.firebase.Timestamp
import com.google.firebase.firestore.PropertyName
import java.util.UUID

data class PrayerRequest(
    @get:PropertyName("id")
    val id: String = UUID.randomUUID().toString(),
    
    @get:PropertyName("name")
    val name: String = "",
    
    @get:PropertyName("email")
    val email: String = "",
    
    @get:PropertyName("phone")
    val phone: String = "",
    
    @get:PropertyName("request")
    val request: String = "",
    
    @get:PropertyName("timestamp")
    val timestamp: Timestamp = Timestamp.now(),
    
    @get:PropertyName("status")
    val status: RequestStatus = RequestStatus.NEW,
    
    @get:PropertyName("isPrivate")
    val isPrivate: Boolean = false,
    
    @get:PropertyName("requestType")
    val requestType: RequestType = RequestType.PERSONAL
)

enum class RequestStatus {
    @PropertyName("new")
    NEW,
    @PropertyName("approved")
    APPROVED,
    @PropertyName("rejected")
    REJECTED;

    override fun toString(): String {
        return when (this) {
            NEW -> "new"
            APPROVED -> "approved"
            REJECTED -> "rejected"
        }
    }

    companion object {
        fun fromString(value: String): RequestStatus {
            return when (value.lowercase()) {
                "new" -> NEW
                "approved" -> APPROVED
                "rejected" -> REJECTED
                else -> NEW
            }
        }
    }
}

enum class RequestType {
    @PropertyName("Personal")
    PERSONAL,
    @PropertyName("Family")
    FAMILY,
    @PropertyName("Health")
    HEALTH,
    @PropertyName("Financial")
    FINANCIAL,
    @PropertyName("Spiritual")
    SPIRITUAL,
    @PropertyName("Other")
    OTHER;

    override fun toString(): String {
        return when (this) {
            PERSONAL -> "Personal"
            FAMILY -> "Family"
            HEALTH -> "Health"
            FINANCIAL -> "Financial"
            SPIRITUAL -> "Spiritual"
            OTHER -> "Other"
        }
    }

    companion object {
        fun fromString(value: String): RequestType {
            return when (value) {
                "Personal" -> PERSONAL
                "Family" -> FAMILY
                "Health" -> HEALTH
                "Financial" -> FINANCIAL
                "Spiritual" -> SPIRITUAL
                "Other" -> OTHER
                else -> PERSONAL
            }
        }
    }
}
