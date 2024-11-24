package com.rtsda.appr.data.model

import com.google.firebase.Timestamp
import com.google.firebase.firestore.DocumentId
import com.google.firebase.firestore.PropertyName
import com.google.firebase.firestore.Exclude
import java.util.UUID

data class PrayerRequest(
    @DocumentId
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
) {
    @Exclude
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "id" to id,
            "name" to name,
            "email" to email,
            "phone" to phone,
            "request" to request,
            "timestamp" to timestamp,
            "status" to status.toString(),
            "isPrivate" to isPrivate,
            "requestType" to requestType.toString()
        )
    }

    companion object {
        fun fromMap(map: Map<String, Any?>): PrayerRequest {
            return PrayerRequest(
                id = map["id"] as? String ?: UUID.randomUUID().toString(),
                name = map["name"] as? String ?: "",
                email = map["email"] as? String ?: "",
                phone = map["phone"] as? String ?: "",
                request = map["request"] as? String ?: "",
                timestamp = (map["timestamp"] as? Timestamp) ?: Timestamp.now(),
                status = try {
                    RequestStatus.fromString(map["status"] as? String ?: "")
                } catch (e: Exception) {
                    RequestStatus.NEW
                },
                isPrivate = map["isPrivate"] as? Boolean ?: false,
                requestType = try {
                    RequestType.fromString(map["requestType"] as? String ?: "")
                } catch (e: Exception) {
                    RequestType.PERSONAL
                }
            )
        }
    }
}
