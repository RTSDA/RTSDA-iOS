package com.rtsda.appr.util

import com.google.firebase.Timestamp
import com.google.firebase.firestore.FirebaseFirestore
import kotlinx.coroutines.tasks.await
import android.util.Log
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class DatabaseMigration @Inject constructor(
    private val db: FirebaseFirestore
) {
    suspend fun migrateTimestamps() {
        try {
            val eventsSnapshot = db.collection("events").get().await()
            var migratedCount = 0
            var timestampCount = 0
            var doubleCount = 0
            
            Log.d("RTSDA_MIGRATION", "Starting timestamp migration check for ${eventsSnapshot.size()} events")
            
            eventsSnapshot.documents.forEach { doc ->
                val data = doc.data ?: return@forEach
                var needsUpdate = false
                val updates = mutableMapOf<String, Any>()

                // Check and convert startDate
                when (val startValue = data["startDate"]) {
                    is Double -> {
                        updates["startDate"] = Timestamp(startValue.toLong(), 0)
                        needsUpdate = true
                        doubleCount++
                        Log.d("RTSDA_MIGRATION", "Event ${doc.id}: startDate is Double")
                    }
                    is Timestamp -> {
                        timestampCount++
                        Log.d("RTSDA_MIGRATION", "Event ${doc.id}: startDate is already Timestamp")
                    }
                    else -> {
                        Log.w("RTSDA_MIGRATION", "Event ${doc.id}: startDate is unexpected type: ${startValue?.javaClass?.simpleName}")
                    }
                }

                // Check and convert endDate
                when (val endValue = data["endDate"]) {
                    is Double -> {
                        updates["endDate"] = Timestamp(endValue.toLong(), 0)
                        needsUpdate = true
                        doubleCount++
                        Log.d("RTSDA_MIGRATION", "Event ${doc.id}: endDate is Double")
                    }
                    is Timestamp -> {
                        timestampCount++
                        Log.d("RTSDA_MIGRATION", "Event ${doc.id}: endDate is already Timestamp")
                    }
                    else -> {
                        Log.w("RTSDA_MIGRATION", "Event ${doc.id}: endDate is unexpected type: ${endValue?.javaClass?.simpleName}")
                    }
                }

                if (needsUpdate) {
                    try {
                        db.collection("events")
                            .document(doc.id)
                            .update(updates)
                            .await()
                        migratedCount++
                        Log.d("RTSDA_MIGRATION", "Successfully migrated event ${doc.id}")
                    } catch (e: Exception) {
                        Log.e("RTSDA_MIGRATION", "Failed to migrate event ${doc.id}", e)
                    }
                }
            }

            Log.i("RTSDA_MIGRATION", """
                Migration check completed:
                - Total events checked: ${eventsSnapshot.size()}
                - Already Timestamp format: $timestampCount
                - Double format (converted): $doubleCount
                - Successfully migrated: $migratedCount
            """.trimIndent())
        } catch (e: Exception) {
            Log.e("RTSDA_MIGRATION", "Failed to complete timestamp migration", e)
            throw e
        }
    }
}
