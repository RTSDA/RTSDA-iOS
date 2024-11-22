package com.rtsda.appr.ui.screens

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.navigation.NavController
import androidx.navigation.compose.rememberNavController
import com.rtsda.appr.R
import com.rtsda.appr.ui.components.QuickLinkButton
import com.rtsda.appr.ui.components.dialogs.ServiceTimesDialog

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(navController: NavController) {
    var showServiceTimes by remember { mutableStateOf(false) }
    val context = LocalContext.current
    val churchAddress = "9 Hartford Turnpike, Tolland, CT 06084"

    Scaffold { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(padding),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Church Logo/Header
            Image(
                painter = painterResource(id = R.drawable.second_coming),
                contentDescription = "Church Logo",
                modifier = Modifier
                    .fillMaxWidth()
                    .height(200.dp)
                    .padding(16.dp),
                contentScale = ContentScale.Fit
            )

            // Welcome Message
            Text(
                text = "Welcome to\nRockville-Tolland SDA Church",
                style = MaterialTheme.typography.headlineMedium,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(16.dp)
            )

            // Quick Links
            Column(
                modifier = Modifier
                    .padding(16.dp)
                    .fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                QuickLinkButton(
                    title = "Service Times",
                    icon = Icons.Default.Schedule,
                    onClick = { showServiceTimes = true }
                )

                QuickLinkButton(
                    title = "Directions",
                    icon = Icons.Default.Map,
                    onClick = {
                        val gmmIntentUri = Uri.parse("geo:0,0?q=$churchAddress")
                        val mapIntent = Intent(Intent.ACTION_VIEW, gmmIntentUri)
                        mapIntent.setPackage("com.google.android.apps.maps")
                        if (mapIntent.resolveActivity(context.packageManager) != null) {
                            context.startActivity(mapIntent)
                        } else {
                            // Fallback to browser if Google Maps isn't installed
                            val browserIntent = Intent(
                                Intent.ACTION_VIEW,
                                Uri.parse("https://www.google.com/maps/search/?api=1&query=$churchAddress")
                            )
                            context.startActivity(browserIntent)
                        }
                    }
                )

                QuickLinkButton(
                    title = "Give Online",
                    icon = Icons.Default.Favorite,
                    onClick = { navController.navigate("give_online") }
                )

                QuickLinkButton(
                    title = "Prayer Request",
                    icon = Icons.Default.Favorite,
                    onClick = { navController.navigate("prayer_request") }
                )
            }
        }
    }

    // Dialogs
    if (showServiceTimes) {
        ServiceTimesDialog(
            onDismiss = { showServiceTimes = false }
        )
    }
}
