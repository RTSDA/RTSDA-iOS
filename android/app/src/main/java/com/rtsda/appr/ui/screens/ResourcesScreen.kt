package com.rtsda.appr.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.LibraryBooks
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.automirrored.filled.OpenInNew
import androidx.compose.material.icons.filled.Book
import androidx.compose.material.icons.filled.MusicNote
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.unit.dp

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ResourcesScreen(
    onDismiss: () -> Unit,
    modifier: Modifier = Modifier
) {
    val uriHandler = LocalUriHandler.current
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Church Resources") },
                navigationIcon = {
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            ResourceItem(
                icon = Icons.Default.Book,
                title = "Bible",
                onClick = {
                    try {
                        // Try to open the Bible app
                        uriHandler.openUri("com.sirma.mobile.bible.android://")
                    } catch (e: Exception) {
                        try {
                            // If app isn't installed, try to open Play Store app
                            uriHandler.openUri("market://details?id=com.sirma.mobile.bible.android")
                        } catch (e: Exception) {
                            try {
                                // If Play Store app isn't available, try Play Store web
                                uriHandler.openUri("https://play.google.com/store/apps/details?id=com.sirma.mobile.bible.android")
                            } catch (e: Exception) {
                                // Final fallback: open Bible website
                                uriHandler.openUri("https://www.bible.com")
                            }
                        }
                    }
                }
            )

            ResourceItem(
                icon = Icons.Default.MusicNote,
                title = "SDA Hymnal",
                onClick = {
                    try {
                        // Try to open the Hymnal app
                        uriHandler.openUri("sld.sdahymnal.com://")
                    } catch (e: Exception) {
                        try {
                            // If app isn't installed, try to open Play Store app
                            uriHandler.openUri("market://details?id=sld.sdahymnal.com")
                        } catch (e: Exception) {
                            // If Play Store isn't available, open Play Store web
                            uriHandler.openUri("https://play.google.com/store/apps/details?id=sld.sdahymnal.com")
                        }
                    }
                }
            )

            ResourceItem(
                icon = Icons.AutoMirrored.Filled.MenuBook,
                title = "Sabbath School Quarterly",
                onClick = {
                    try {
                        // Try to open the Sabbath School app
                        uriHandler.openUri("com.googleusercontent.apps.443920152945-d0kf5h2dubt0jbcntq8l0qeg6lbpgn60://")
                    } catch (e: Exception) {
                        try {
                            // If app isn't installed, try to open Play Store
                            uriHandler.openUri("market://details?id=com.cryart.sabbathschool")
                        } catch (e: Exception) {
                            // If Play Store isn't available, open web
                            uriHandler.openUri("https://play.google.com/store/apps/details?id=com.cryart.sabbathschool")
                        }
                    }
                }
            )
            
            ResourceItem(
                icon = Icons.AutoMirrored.Filled.LibraryBooks,
                title = "Ellen G. White Writings",
                onClick = {
                    try {
                        // Try to open the EGW Writings app
                        uriHandler.openUri("com.whiteestate.egwwritings://")
                    } catch (e: Exception) {
                        try {
                            // If app isn't installed, try to open Play Store app
                            uriHandler.openUri("market://details?id=com.whiteestate.egwwritings")
                        } catch (e: Exception) {
                            try {
                                // If Play Store app isn't available, try Play Store web
                                uriHandler.openUri("https://play.google.com/store/apps/details?id=com.whiteestate.egwwritings")
                            } catch (e: Exception) {
                                // Final fallback: open EGW Writings website
                                uriHandler.openUri("https://egwwritings.org/")
                            }
                        }
                    }
                }
            )
        }
    }
}

@Composable
private fun ResourceItem(
    icon: ImageVector,
    title: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        onClick = onClick
    ) {
        Row(
            modifier = Modifier
                .padding(16.dp)
                .fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary
            )
            Text(
                text = title,
                style = MaterialTheme.typography.titleMedium
            )
            Spacer(modifier = Modifier.weight(1f))
            Icon(
                imageVector = Icons.AutoMirrored.Filled.OpenInNew,
                contentDescription = "Open link",
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}
