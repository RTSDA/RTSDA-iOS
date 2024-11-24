package com.rtsda.appr.service

import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.Query
import com.rtsda.appr.data.model.PrayerRequest
import com.rtsda.appr.data.model.RequestStatus
import com.rtsda.appr.data.model.RequestType
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.tasks.await
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class PrayerRequestService @Inject constructor(
    private val db: FirebaseFirestore
) {
    private val collection = db.collection("prayerRequests")

    // Submit a new prayer request (matches iOS implementation)
    suspend fun submitPrayerRequest(
        name: String,
        email: String,
        phone: String,
        request: String,
        isPrivate: Boolean,
        requestType: RequestType
    ) {
        val prayerRequest = PrayerRequest(
            name = name,
            email = email,
            phone = phone,
            request = request,
            isPrivate = isPrivate,
            requestType = requestType,
            status = RequestStatus.NEW
        )
        try {
            collection.add(prayerRequest.toMap()).await()
        } catch (e: Exception) {
            throw e
        }
    }

    // Get all prayer requests as a Flow (for admin)
    fun getPrayerRequests(): Flow<List<PrayerRequest>> = callbackFlow {
        val subscription = collection
            .orderBy("timestamp", Query.Direction.DESCENDING)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    close(error)
                    return@addSnapshotListener
                }

                if (snapshot != null) {
                    val requests = snapshot.documents.mapNotNull { doc ->
                        try {
                            PrayerRequest.fromDocument(doc)
                        } catch (e: Exception) {
                            e.printStackTrace()
                            null
                        }
                    }
                    trySend(requests)
                }
            }

        awaitClose { subscription.remove() }
    }

    // Update prayer request status (matches iOS implementation)
    suspend fun updatePrayerRequestStatus(requestId: String, status: RequestStatus) {
        try {
            collection.document(requestId)
                .update("status", status.toString())
                .await()
        } catch (e: Exception) {
            throw e
        }
    }

    // Delete a prayer request (matches iOS implementation)
    suspend fun deletePrayerRequest(requestId: String) {
        try {
            collection.document(requestId)
                .delete()
                .await()
        } catch (e: Exception) {
            throw e
        }
    }
}
