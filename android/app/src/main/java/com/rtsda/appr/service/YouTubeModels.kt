package com.rtsda.appr.service

data class SearchResponse(
    val items: List<SearchItem> = emptyList()
)

data class SearchItem(
    val id: VideoId,
    val snippet: Snippet
)

data class VideoId(
    val kind: String,
    val videoId: String
)

data class Snippet(
    val title: String,
    val description: String,
    val thumbnails: Thumbnails
)

data class Thumbnails(
    val high: Thumbnail
)

data class Thumbnail(
    val url: String
)
