package com.rtsda.appr.ui.screens.admin

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AdminSettingsScreen(
    onDismiss: () -> Unit,
    viewModel: AdminViewModel = hiltViewModel()
) {
    var showConfirmDialog by remember { mutableStateOf(false) }
    var selectedAction: (() -> Unit)? by remember { mutableStateOf(null) }
    var confirmationMessage by remember { mutableStateOf("") }

    LaunchedEffect(viewModel.isAdmin) {
        if (!viewModel.isAdmin) {
            onDismiss()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Admin Settings") },
                navigationIcon = {
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            item {
                SettingsSection(title = "App Settings") {
                    SettingsItem(
                        icon = Icons.Default.Notifications,
                        title = "Push Notifications",
                        subtitle = "Configure push notification settings",
                        onClick = {
                            confirmationMessage = "Configure push notifications?"
                            selectedAction = {
                                // TODO: Implement push notification settings
                            }
                            showConfirmDialog = true
                        }
                    )
                    
                    SettingsItem(
                        icon = Icons.Default.Storage,
                        title = "Clear App Cache",
                        subtitle = "Clear temporary app data",
                        onClick = {
                            confirmationMessage = "Are you sure you want to clear the app cache?"
                            selectedAction = {
                                // TODO: Implement cache clearing
                            }
                            showConfirmDialog = true
                        }
                    )
                }
            }
            
            item {
                SettingsSection(title = "User Management") {
                    SettingsItem(
                        icon = Icons.Default.SupervisorAccount,
                        title = "Manage Admins",
                        subtitle = "Add or remove admin users",
                        onClick = {
                            confirmationMessage = "Manage admin users?"
                            selectedAction = {
                                // TODO: Implement admin management
                            }
                            showConfirmDialog = true
                        }
                    )
                }
            }
        }
    }

    if (showConfirmDialog) {
        AlertDialog(
            onDismissRequest = { showConfirmDialog = false },
            title = { Text("Confirm Action") },
            text = { Text(confirmationMessage) },
            confirmButton = {
                TextButton(
                    onClick = {
                        selectedAction?.invoke()
                        showConfirmDialog = false
                    }
                ) {
                    Text("Confirm")
                }
            },
            dismissButton = {
                TextButton(
                    onClick = { showConfirmDialog = false }
                ) {
                    Text("Cancel")
                }
            }
        )
    }
}

@Composable
private fun SettingsSection(
    title: String,
    content: @Composable ColumnScope.() -> Unit
) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Text(
            text = title,
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.primary,
            modifier = Modifier.padding(vertical = 8.dp)
        )
        Card(
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(
                modifier = Modifier.fillMaxWidth()
            ) {
                content()
            }
        }
    }
}

@Composable
private fun SettingsItem(
    icon: ImageVector,
    title: String,
    subtitle: String,
    onClick: () -> Unit
) {
    Surface(
        onClick = onClick,
        color = MaterialTheme.colorScheme.surface
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                modifier = Modifier.padding(end = 16.dp)
            )
            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleSmall
                )
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Icon(
                imageVector = Icons.Default.ChevronRight,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}
