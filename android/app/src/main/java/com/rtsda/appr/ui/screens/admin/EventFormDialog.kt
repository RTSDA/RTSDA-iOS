package com.rtsda.appr.ui.screens.admin

import android.app.DatePickerDialog
import android.app.TimePickerDialog
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.google.firebase.Timestamp
import com.rtsda.appr.data.model.CalendarEvent
import com.rtsda.appr.data.model.RecurrenceType
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EventFormDialog(
    event: CalendarEvent?,
    onDismiss: () -> Unit,
    onSave: (CalendarEvent) -> Unit
) {
    var title by remember(event) { mutableStateOf(event?.title ?: "") }
    var description by remember(event) { mutableStateOf(event?.description ?: "") }
    var location by remember(event) { mutableStateOf(event?.location ?: "") }
    var startDate by remember(event) { mutableStateOf(event?.startDate?.toDate() ?: Date()) }
    var endDate by remember(event) { mutableStateOf(event?.endDate?.toDate() ?: Date(startDate.time + 3600000)) }
    var recurrenceType by remember(event) { mutableStateOf(event?.recurrenceType ?: RecurrenceType.NONE) }
    var showRecurrenceMenu by remember { mutableStateOf(false) }
    
    val context = LocalContext.current
    val dateFormatter = SimpleDateFormat("MM/dd/yyyy hh:mm a", Locale.getDefault())
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(if (event == null) "Add Event" else "Edit Event") },
        text = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Title
                OutlinedTextField(
                    value = title,
                    onValueChange = { title = it },
                    label = { Text("Title") },
                    modifier = Modifier.fillMaxWidth()
                )
                
                // Description
                OutlinedTextField(
                    value = description,
                    onValueChange = { description = it },
                    label = { Text("Description") },
                    modifier = Modifier.fillMaxWidth(),
                    minLines = 3
                )
                
                // Location
                OutlinedTextField(
                    value = location,
                    onValueChange = { location = it },
                    label = { Text("Location") },
                    modifier = Modifier.fillMaxWidth()
                )
                
                // Start Date
                OutlinedTextField(
                    value = dateFormatter.format(startDate),
                    onValueChange = { /* Will be handled by date picker */ },
                    label = { Text("Start Date & Time") },
                    modifier = Modifier.fillMaxWidth(),
                    readOnly = true,
                    trailingIcon = {
                        IconButton(onClick = {
                            val calendar = Calendar.getInstance().apply { time = startDate }
                            
                            DatePickerDialog(
                                context,
                                { _, year, month, day ->
                                    TimePickerDialog(
                                        context,
                                        { _, hour, minute ->
                                            calendar.set(year, month, day, hour, minute)
                                            startDate = calendar.time
                                        },
                                        calendar.get(Calendar.HOUR_OF_DAY),
                                        calendar.get(Calendar.MINUTE),
                                        false
                                    ).show()
                                },
                                calendar.get(Calendar.YEAR),
                                calendar.get(Calendar.MONTH),
                                calendar.get(Calendar.DAY_OF_MONTH)
                            ).show()
                        }) {
                            Icon(
                                imageVector = Icons.Filled.CalendarToday,
                                contentDescription = "Select date and time"
                            )
                        }
                    }
                )
                
                // End Date
                OutlinedTextField(
                    value = dateFormatter.format(endDate),
                    onValueChange = { /* Will be handled by date picker */ },
                    label = { Text("End Date & Time") },
                    modifier = Modifier.fillMaxWidth(),
                    readOnly = true,
                    trailingIcon = {
                        IconButton(onClick = {
                            val calendar = Calendar.getInstance().apply { time = endDate }
                            
                            DatePickerDialog(
                                context,
                                { _, year, month, day ->
                                    TimePickerDialog(
                                        context,
                                        { _, hour, minute ->
                                            calendar.set(year, month, day, hour, minute)
                                            endDate = calendar.time
                                        },
                                        calendar.get(Calendar.HOUR_OF_DAY),
                                        calendar.get(Calendar.MINUTE),
                                        false
                                    ).show()
                                },
                                calendar.get(Calendar.YEAR),
                                calendar.get(Calendar.MONTH),
                                calendar.get(Calendar.DAY_OF_MONTH)
                            ).show()
                        }) {
                            Icon(
                                imageVector = Icons.Filled.CalendarToday,
                                contentDescription = "Select date and time"
                            )
                        }
                    }
                )
                
                // Recurrence Type
                ExposedDropdownMenuBox(
                    expanded = showRecurrenceMenu,
                    onExpandedChange = { showRecurrenceMenu = it }
                ) {
                    OutlinedTextField(
                        value = recurrenceType.toDisplayString(),
                        onValueChange = {},
                        label = { Text("Recurrence") },
                        modifier = Modifier.fillMaxWidth().menuAnchor(),
                        readOnly = true,
                        trailingIcon = {
                            ExposedDropdownMenuDefaults.TrailingIcon(expanded = showRecurrenceMenu)
                        }
                    )
                    
                    ExposedDropdownMenu(
                        expanded = showRecurrenceMenu,
                        onDismissRequest = { showRecurrenceMenu = false }
                    ) {
                        RecurrenceType.values().forEach { type ->
                            DropdownMenuItem(
                                text = { Text(type.toDisplayString()) },
                                onClick = {
                                    recurrenceType = type
                                    showRecurrenceMenu = false
                                }
                            )
                        }
                    }
                }
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    val newEvent = (event ?: CalendarEvent()).copy(
                        title = title,
                        description = description,
                        location = location,
                        startDate = Timestamp(startDate.time / 1000, 0),
                        endDate = Timestamp(endDate.time / 1000, 0),
                        recurrenceType = recurrenceType
                    )
                    onSave(newEvent)
                }
            ) {
                Text("Save")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}
