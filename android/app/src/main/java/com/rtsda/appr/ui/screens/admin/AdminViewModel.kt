package com.rtsda.appr.ui.screens.admin

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import javax.inject.Inject

@HiltViewModel
class AdminViewModel @Inject constructor(
    private val auth: FirebaseAuth,
    private val firestore: FirebaseFirestore
) : ViewModel() {
    var isAdmin by mutableStateOf(false)
    var isLoading by mutableStateOf(false)
    var error by mutableStateOf<String?>(null)

    init {
        checkAdminStatus()
    }

    private fun checkAdminStatus() {
        viewModelScope.launch {
            try {
                val user = auth.currentUser
                if (user != null) {
                    val adminDoc = firestore.collection("admins")
                        .document(user.uid)
                        .get()
                        .await()

                    isAdmin = adminDoc.exists()
                } else {
                    isAdmin = false
                }
            } catch (e: Exception) {
                error = "Error checking admin status"
                isAdmin = false
            }
        }
    }

    fun signIn(email: String, password: String) {
        viewModelScope.launch {
            isLoading = true
            error = null
            try {
                auth.signInWithEmailAndPassword(email, password).await()
                checkAdminStatus()
            } catch (e: Exception) {
                error = "Invalid email or password"
                isAdmin = false
            } finally {
                isLoading = false
            }
        }
    }

    fun signOut() {
        viewModelScope.launch {
            try {
                auth.signOut()
                isAdmin = false
                error = null
            } catch (e: Exception) {
                error = "Error signing out"
            }
        }
    }
}
