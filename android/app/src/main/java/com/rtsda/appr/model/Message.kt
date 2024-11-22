package com.rtsda.appr.model

data class Message(
    val id: String,
    val title: String,
    val description: String,
    val thumbnailUrl: String,
    val isLivestream: Boolean
)
