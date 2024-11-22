package com.rtsda.appr.service

import android.util.Log
import com.google.gson.Gson
import com.rtsda.appr.BuildConfig
import com.rtsda.appr.model.Message
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import java.util.*
import javax.inject.Inject
import javax.inject.Singleton
import java.util.regex.Pattern

@Singleton
class YouTubeService @Inject constructor(
    private val client: OkHttpClient,
    private val gson: Gson
) {
    private val apiKey = BuildConfig.YOUTUBE_API_KEY
    private val channelId = BuildConfig.YOUTUBE_CHANNEL_ID
    private val cacheDuration = 15 * 60 * 1000L // 15 minutes
    
    private var cachedSermon: Message? = null
    private var cachedLivestream: Message? = null
    private var lastFetchTime: Date? = null
    private val mutex = Mutex()
    
    suspend fun getLatestSermon(): Message? = mutex.withLock {
        if (shouldRefreshCache()) {
            refreshCache()
        }
        return cachedSermon
    }
    
    suspend fun getUpcomingLivestream(): Message? = mutex.withLock {
        if (shouldRefreshCache()) {
            refreshCache()
        }
        return cachedLivestream
    }
    
    private fun shouldRefreshCache(): Boolean {
        val now = Date()
        return lastFetchTime?.let { last ->
            now.time - last.time > cacheDuration
        } ?: true
    }
    
    private suspend fun refreshCache() {
        try {
            fetchVideos()
            lastFetchTime = Date()
        } catch (e: Exception) {
            Log.e("YouTubeService", "Error refreshing cache", e)
        }
    }
    
    private suspend fun fetchVideos() {
        try {
            // First search for upcoming livestreams
            val upcomingUrl = buildString {
                append("https://www.googleapis.com/youtube/v3/search")
                append("?key=$apiKey")
                append("&channelId=$channelId")
                append("&part=snippet,id")
                append("&type=video")
                append("&eventType=upcoming")
                append("&maxResults=1")
            }
            
            val upcomingResponse = makeRequest(upcomingUrl)
            val upcomingSearchResponse = gson.fromJson(upcomingResponse, SearchResponse::class.java)
            
            // Set livestream if found
            upcomingSearchResponse.items.firstOrNull()?.let { livestream ->
                Log.d("YouTubeService", "Found upcoming livestream: ${livestream.snippet.title}")
                cachedLivestream = Message(
                    id = livestream.id.videoId,
                    title = livestream.snippet.title,
                    description = livestream.snippet.description,
                    thumbnailUrl = livestream.snippet.thumbnails.high.url,
                    isLivestream = true
                )
            }
            
            // Then search for regular videos (potential sermons)
            val regularUrl = buildString {
                append("https://www.googleapis.com/youtube/v3/search")
                append("?key=$apiKey")
                append("&channelId=$channelId")
                append("&part=snippet,id")
                append("&type=video")
                append("&order=date")
                append("&maxResults=10")
            }
            
            val regularResponse = makeRequest(regularUrl)
            Log.d("YouTubeService", "Regular videos response: $regularResponse")
            val regularSearchResponse = gson.fromJson(regularResponse, SearchResponse::class.java)
            
            val videos = regularSearchResponse.items
            Log.d("YouTubeService", "Found ${videos.size} regular videos")
            
            // Look for most recent sermon
            videos.firstOrNull { video ->
                val title = video.snippet.title.uppercase()
                val description = video.snippet.description.uppercase()
                
                Log.d("YouTubeService", "Checking regular video: ${video.snippet.title}")
                
                // Exclude videos with "worship service" in the title
                val isNotWorshipService = !title.contains("WORSHIP SERVICE") && 
                                        !title.contains("DIVINE SERVICE") &&
                                        !title.contains("DIVINE WORSHIP")
                
                val isSermon = (title.contains("SERMON") || 
                             title.contains("SABBATH") ||
                             title.contains("MESSAGE") ||
                             description.contains("SERMON") ||
                             description.contains("SABBATH MESSAGE"))
                
                val isNotShort = !title.contains("#SHORTS") && !title.contains("SHORT")
                val isNotLive = !title.contains("LIVE") && video.snippet.liveBroadcastContent != "upcoming"
                
                // Check video duration
                val duration = getVideoDuration(video.id.videoId)
                val isLongEnough = duration >= 60
                
                Log.d("YouTubeService", """
                    Video check:
                    Title: ${video.snippet.title}
                    Is sermon: $isSermon
                    Is not worship service: $isNotWorshipService
                    Is not short: $isNotShort
                    Is not live: $isNotLive
                    Duration: ${duration}s
                    Is long enough: $isLongEnough
                """.trimIndent())
                
                isSermon && isNotWorshipService && isNotShort && isNotLive && isLongEnough
            }?.let { sermon ->
                Log.d("YouTubeService", "Found sermon: ${sermon.snippet.title}")
                cachedSermon = Message(
                    id = sermon.id.videoId,
                    title = sermon.snippet.title,
                    description = sermon.snippet.description,
                    thumbnailUrl = sermon.snippet.thumbnails.high.url,
                    isLivestream = false
                )
            } ?: Log.d("YouTubeService", "No sermon found in regular videos")
            
        } catch (e: Exception) {
            Log.e("YouTubeService", "Error fetching videos: ${e.message}")
            e.printStackTrace()
        }
    }
    
    private suspend fun makeRequest(url: String): String = withContext(Dispatchers.IO) {
        val request = Request.Builder()
            .url(url)
            .build()
            
        client.newCall(request).execute().use { response ->
            if (!response.isSuccessful) {
                throw Exception("API call failed with code ${response.code}")
            }
            return@withContext response.body?.string() ?: throw Exception("Empty response body")
        }
    }
    
    data class SearchResponse(
        val items: List<SearchResult>
    )

    data class SearchResult(
        val id: VideoId,
        val snippet: Snippet
    )

    data class VideoId(
        val videoId: String
    )

    data class Snippet(
        val title: String,
        val description: String,
        val thumbnails: Thumbnails,
        val liveBroadcastContent: String
    )

    data class Thumbnails(
        val high: ThumbnailDetails
    )

    data class ThumbnailDetails(
        val url: String
    )

    data class VideoResponse(
        val items: List<VideoItem>
    )
    
    data class VideoItem(
        val contentDetails: ContentDetails
    )
    
    data class ContentDetails(
        val duration: String
    )
    
    private fun parseDuration(duration: String): Long {
        var seconds = 0L
        val pattern = Pattern.compile("PT(?:(\\d+)H)?(?:(\\d+)M)?(?:(\\d+)S)?")
        val matcher = pattern.matcher(duration)
        
        if (matcher.find()) {
            val hours = matcher.group(1)?.toLong() ?: 0
            val minutes = matcher.group(2)?.toLong() ?: 0
            val secs = matcher.group(3)?.toLong() ?: 0
            
            seconds = hours * 3600 + minutes * 60 + secs
        }
        return seconds
    }
    
    private suspend fun getVideoDuration(videoId: String): Long {
        try {
            val url = buildString {
                append("https://www.googleapis.com/youtube/v3/videos")
                append("?key=$apiKey")
                append("&id=$videoId")
                append("&part=contentDetails")
            }
            
            val response = makeRequest(url)
            val videoResponse = gson.fromJson(response, VideoResponse::class.java)
            
            return videoResponse.items.firstOrNull()?.let { video ->
                parseDuration(video.contentDetails.duration)
            } ?: 0
        } catch (e: Exception) {
            Log.e("YouTubeService", "Error getting video duration: ${e.message}")
            return 0
        }
    }
}
