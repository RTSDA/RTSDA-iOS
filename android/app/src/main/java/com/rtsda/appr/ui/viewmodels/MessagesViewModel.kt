package com.rtsda.appr.ui.viewmodels

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.rtsda.appr.model.Message
import com.rtsda.appr.service.YouTubeService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.async
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class MessagesUiState(
    val messages: List<Message> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null
)

@HiltViewModel
class MessagesViewModel @Inject constructor(
    private val youTubeService: YouTubeService
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(MessagesUiState())
    val uiState: StateFlow<MessagesUiState> = _uiState.asStateFlow()
    
    init {
        Log.d("MessagesViewModel", "Initializing ViewModel")
        refresh()
    }
    
    fun refresh() {
        Log.d("MessagesViewModel", "Refreshing content")
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            
            try {
                Log.d("MessagesViewModel", "Fetching content")
                
                // Add a minimum refresh time of 1 second
                val startTime = System.currentTimeMillis()
                
                // Fetch both sermon and livestream concurrently
                val sermonDeferred = async { youTubeService.getLatestSermon() }
                val livestreamDeferred = async { youTubeService.getUpcomingLivestream() }
                
                val latestSermon = sermonDeferred.await()
                val upcomingLivestream = livestreamDeferred.await()
                
                // Combine results, putting livestream first if it exists
                val messages = buildList {
                    upcomingLivestream?.let { add(it) }
                    latestSermon?.let { add(it) }
                }
                
                Log.d("MessagesViewModel", "Content fetched. Messages: ${messages.size}, Livestream: ${upcomingLivestream != null}, Sermon: ${latestSermon != null}")
                
                // Ensure minimum refresh time of 1 second
                val elapsedTime = System.currentTimeMillis() - startTime
                if (elapsedTime < 1000) {
                    delay(1000 - elapsedTime)
                }
                
                _uiState.update { it.copy(
                    messages = messages,
                    isLoading = false,
                    error = null
                ) }
            } catch (e: Exception) {
                Log.e("MessagesViewModel", "Error fetching content", e)
                _uiState.update { it.copy(
                    error = e.localizedMessage ?: "An error occurred",
                    isLoading = false
                ) }
            }
        }
    }
}
