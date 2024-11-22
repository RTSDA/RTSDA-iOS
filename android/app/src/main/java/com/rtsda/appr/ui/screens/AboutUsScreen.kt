package com.rtsda.appr.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AboutUsScreen(
    onDismiss: () -> Unit,
    modifier: Modifier = Modifier
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("About Us") },
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
            Text(
                text = "Welcome to Rockville-Tolland Seventh-day Adventist Church",
                style = MaterialTheme.typography.headlineSmall,
                textAlign = TextAlign.Center
            )
            
            Text(
                text = "We are a vibrant, Bible-believing community of faith located in Tolland, Connecticut. " +
                    "Our mission is to share the love of Jesus Christ and prepare people for His soon return.",
                style = MaterialTheme.typography.bodyLarge
            )
            
            Text(
                text = "Service Times",
                style = MaterialTheme.typography.titleLarge
            )
            
            Card {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = "Sabbath School: 9:30 AM",
                        style = MaterialTheme.typography.bodyLarge
                    )
                    Text(
                        text = "Divine Service: 11:00 AM",
                        style = MaterialTheme.typography.bodyLarge
                    )
                    Text(
                        text = "Prayer Meeting: Wednesday 6:30 PM",
                        style = MaterialTheme.typography.bodyLarge
                    )
                }
            }
            
            Text(
                text = "Our Beliefs",
                style = MaterialTheme.typography.titleLarge
            )
            
            Text(
                text = "As Seventh-day Adventists, we believe in:\n\n" +
                    "• The Bible as the inspired word of God\n" +
                    "• Salvation through faith in Jesus Christ\n" +
                    "• The Second Coming of Christ\n" +
                    "• The Sabbath as God's holy day\n" +
                    "• Wholistic living and health\n" +
                    "• Service to humanity",
                style = MaterialTheme.typography.bodyLarge
            )
        }
    }
}
