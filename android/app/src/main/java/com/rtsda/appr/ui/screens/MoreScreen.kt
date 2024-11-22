package com.rtsda.appr.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

data class MoreMenuItem(
    val title: String,
    val icon: androidx.compose.ui.graphics.vector.ImageVector,
    val onClick: () -> Unit
)

@Composable
fun MoreScreen(
    onNavigateToPrayerRequests: () -> Unit,
    onNavigateToGiveOnline: () -> Unit,
    onNavigateToAboutUs: () -> Unit,
    onNavigateToContactUs: () -> Unit,
    onNavigateToSocialMedia: () -> Unit,
    onNavigateToResources: () -> Unit,
    onNavigateToAdmin: () -> Unit,
    modifier: Modifier = Modifier
) {
    val menuItems = listOf(
        MoreMenuItem("Prayer Requests", Icons.Default.Favorite, onNavigateToPrayerRequests),
        MoreMenuItem("Give Online", Icons.Default.CreditCard, onNavigateToGiveOnline),
        MoreMenuItem("About Us", Icons.Default.Info, onNavigateToAboutUs),
        MoreMenuItem("Contact Us", Icons.Default.ContactMail, onNavigateToContactUs),
        MoreMenuItem("Social Media", Icons.Default.Share, onNavigateToSocialMedia),
        MoreMenuItem("Resources", Icons.Default.LibraryBooks, onNavigateToResources),
        MoreMenuItem("Admin", Icons.Default.AdminPanelSettings, onNavigateToAdmin)
    )

    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Text(
            text = "More",
            style = MaterialTheme.typography.headlineMedium,
            modifier = Modifier.padding(bottom = 16.dp)
        )
        
        menuItems.forEach { item ->
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { item.onClick() }
            ) {
                Row(
                    modifier = Modifier
                        .padding(16.dp)
                        .fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = item.icon,
                        contentDescription = item.title,
                        tint = MaterialTheme.colorScheme.primary
                    )
                    Text(
                        text = item.title,
                        style = MaterialTheme.typography.titleMedium
                    )
                    Spacer(modifier = Modifier.weight(1f))
                    Icon(
                        imageVector = Icons.Default.ChevronRight,
                        contentDescription = "Navigate",
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
    }
}
