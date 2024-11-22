package com.rtsda.appr.ui.screens.admin

import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.material3.Surface
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import com.rtsda.appr.data.model.CalendarEvent
import com.rtsda.appr.ui.viewmodels.AdminEventViewModel

@Composable
fun AdminEventFormView(
    viewModel: AdminEventViewModel,
    onDismiss: () -> Unit,
    eventId: String? = null
) {
    val uiState by viewModel.uiState.collectAsState()

    // If editing, load the event
    LaunchedEffect(eventId) {
        if (eventId != null) {
            viewModel.loadEvent(eventId)
        }
    }

    // Handle dismissal cleanup
    DisposableEffect(Unit) {
        onDispose {
            viewModel.clearCache()
        }
    }

    Dialog(
        onDismissRequest = {
            viewModel.clearCache()
            onDismiss()
        }
    ) {
        Surface(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            shape = MaterialTheme.shapes.medium,
            tonalElevation = 8.dp
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp)
            ) {
                if (uiState.error != null) {
                    Text(
                        text = uiState.error ?: "",
                        color = MaterialTheme.colorScheme.error,
                        style = MaterialTheme.typography.bodyMedium,
                        modifier = Modifier.padding(bottom = 8.dp)
                    )
                }
                
                EventFormDialog(
                    event = uiState.eventToEdit,
                    onDismiss = {
                        viewModel.clearCache()
                        onDismiss()
                    },
                    onSave = { updatedEvent ->
                        if (eventId != null) {
                            viewModel.updateEvent(updatedEvent.copy(id = eventId))
                        } else {
                            viewModel.addEvent(updatedEvent)
                        }
                        onDismiss()
                    }
                )
            }
        }
    }
}
