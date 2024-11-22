package com.rtsda.appr.navigation

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.*
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.Icon
import androidx.compose.ui.graphics.vector.ImageVector

sealed class NavigationItem(
    val route: String,
    val icon: ImageVector,
    val title: String
) {
    object Home : NavigationItem("home", Icons.Default.Home, "Home")
    object PrayerRequest : NavigationItem("prayer_request", Icons.AutoMirrored.Filled.Message, "Prayer")
    object Bulletins : NavigationItem("bulletins", Icons.Filled.Description, "Bulletins")
    object Events : NavigationItem("events", Icons.Filled.Event, "Events")
    object Sermons : NavigationItem("messages", Icons.Filled.VideoLibrary, "Sermons")
    object More : NavigationItem("more", Icons.Default.MoreVert, "More")
    
    // More menu items
    object GiveOnline : NavigationItem("give_online", Icons.Filled.CreditCard, "Give")
    object AboutUs : NavigationItem("about_us", Icons.Default.Info, "About Us")
    object ContactUs : NavigationItem("contact_us", Icons.Default.Email, "Contact")
    object SocialMedia : NavigationItem("social_media", Icons.Default.Share, "Social")
    object Resources : NavigationItem("resources", Icons.AutoMirrored.Filled.MenuBook, "Resources")
    object Admin : NavigationItem("admin", Icons.Default.Settings, "Admin")
}

val bottomNavItems = listOf(
    NavigationItem.Home,
    NavigationItem.Bulletins,
    NavigationItem.Events,
    NavigationItem.Sermons,
    NavigationItem.More
)

val moreMenuItems = listOf(
    NavigationItem.PrayerRequest,
    NavigationItem.GiveOnline,
    NavigationItem.AboutUs,
    NavigationItem.ContactUs,
    NavigationItem.SocialMedia,
    NavigationItem.Resources,
    NavigationItem.Admin
)
