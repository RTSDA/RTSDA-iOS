package com.rtsda.appr.service

import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.Query
import com.rtsda.appr.data.model.PrayerRequest
import com.rtsda.appr.data.model.RequestStatus
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.tasks.await

class PrayerRequestService {
    private val db = FirebaseFirestore.getInstance()
    private val collection = db.collection("prayerRequests")

    // Submit a new prayer request
    suspend fun submitRequest(request: PrayerRequest): Boolean {
        return try {
            collection.add(request).await()
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
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
                        doc.toObject(PrayerRequest::class.java)?.copy(id = doc.id)
                    }
                    trySend(requests)
                }
            }

        awaitClose { subscription.remove() }
    }

    // Update prayer request status (for admin)
    suspend fun updateStatus(requestId: String, status: RequestStatus) {
        try {
            collection.document(requestId)
                .update("status", status.toString())
                .await()
        } catch (e: Exception) {
            e.printStackTrace()
            throw e
        }
    }

    // Delete prayer request (for admin)
    suspend fun deleteRequest(requestId: String) {
        try {
            collection.document(requestId)
                .delete()
                .await()
        } catch (e: Exception) {
            e.printStackTrace()
            throw e
        }
    }

    companion object {
        @Volatile
        private var instance: PrayerRequestService? = null

        fun getInstance(): PrayerRequestService {
            return instance ?: synchronized(this) {
                instance ?: PrayerRequestService().also { instance = it }
            }
        }
    }
}
