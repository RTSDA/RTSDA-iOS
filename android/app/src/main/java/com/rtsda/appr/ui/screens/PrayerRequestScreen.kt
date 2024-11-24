package com.rtsda.appr.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.rtsda.appr.viewmodels.PrayerRequestViewModel
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import com.rtsda.appr.data.model.RequestType

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PrayerRequestScreen(
    onDismiss: () -> Unit,
    viewModel: PrayerRequestViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsState()
    var showError by remember { mutableStateOf(false) }
    var showSuccess by remember { mutableStateOf(false) }
    val focusManager = LocalFocusManager.current

    LaunchedEffect(state.isSuccess) {
        if (state.isSuccess) {
            showSuccess = true
        }
    }

    LaunchedEffect(state.error) {
        if (state.error != null) {
            showError = true
        }
    }

    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp),
        shape = MaterialTheme.shapes.large,
        color = MaterialTheme.colorScheme.surface,
        tonalElevation = 2.dp
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
        ) {
            TopAppBar(
                title = { Text("Prayer Request") },
                navigationIcon = {
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.Close, contentDescription = "Close")
                    }
                }
            )

            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(24.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Anonymous Toggle
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(bottom = 8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Submit Anonymously",
                        style = MaterialTheme.typography.bodyLarge
                    )
                    Spacer(modifier = Modifier.weight(1f))
                    Switch(
                        checked = state.isAnonymous,
                        onCheckedChange = { viewModel.updateIsAnonymous(it) }
                    )
                }

                if (state.isAnonymous) {
                    Text(
                        text = "Your prayer request will be submitted anonymously",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                // Name Field (only show if not anonymous)
                if (!state.isAnonymous) {
                    OutlinedTextField(
                        value = state.name,
                        onValueChange = { viewModel.updateName(it) },
                        label = { Text("Name") },
                        leadingIcon = { Icon(Icons.Default.Person, contentDescription = "Name") },
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(bottom = 8.dp),
                        keyboardOptions = KeyboardOptions(
                            imeAction = ImeAction.Next
                        ),
                        keyboardActions = KeyboardActions(
                            onNext = { focusManager.moveFocus(FocusDirection.Next) }
                        ),
                        singleLine = true,
                        isError = state.nameError != null,
                        supportingText = { state.nameError?.let { Text(it) } }
                    )
                }

                // Email Field
                OutlinedTextField(
                    value = state.email,
                    onValueChange = { viewModel.updateEmail(it) },
                    label = { Text("Email") },
                    leadingIcon = { Icon(Icons.Default.Email, contentDescription = "Email") },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(bottom = 8.dp),
                    keyboardOptions = KeyboardOptions(
                        keyboardType = KeyboardType.Email,
                        imeAction = ImeAction.Next
                    ),
                    keyboardActions = KeyboardActions(
                        onNext = { focusManager.moveFocus(FocusDirection.Next) }
                    ),
                    isError = state.emailError != null,
                    supportingText = { state.emailError?.let { Text(it) } },
                    singleLine = true
                )

                // Phone Field
                OutlinedTextField(
                    value = state.phone,
                    onValueChange = { viewModel.updatePhone(it) },
                    label = { Text("Phone (Optional)") },
                    keyboardOptions = KeyboardOptions(
                        keyboardType = KeyboardType.Phone,
                        imeAction = ImeAction.Next
                    ),
                    keyboardActions = KeyboardActions(
                        onNext = { focusManager.moveFocus(FocusDirection.Down) }
                    ),
                    singleLine = true,
                    isError = state.phoneError != null,
                    supportingText = state.phoneError?.let { { Text(it) } },
                    leadingIcon = {
                        Icon(
                            imageVector = Icons.Default.Phone,
                            contentDescription = null
                        )
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 8.dp)
                )

                // Request Type Selection
                Text(
                    text = "Request Type",
                    style = MaterialTheme.typography.titleMedium,
                    modifier = Modifier.padding(vertical = 8.dp)
                )
                
                LazyVerticalGrid(
                    columns = GridCells.Fixed(2),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                    modifier = Modifier.height(160.dp)
                ) {
                    items(RequestType.values()) { type ->
                        FilterChip(
                            selected = state.requestType == type,
                            onClick = { viewModel.updateRequestType(type) },
                            label = { Text(type.toString()) },
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Prayer Request Field
                OutlinedTextField(
                    value = state.request,
                    onValueChange = { viewModel.updateRequest(it) },
                    label = { Text("Prayer Request") },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(120.dp),
                    keyboardOptions = KeyboardOptions(
                        keyboardType = KeyboardType.Text,
                        imeAction = ImeAction.Done
                    ),
                    keyboardActions = KeyboardActions(
                        onDone = { focusManager.clearFocus() }
                    ),
                    isError = state.requestError != null,
                    supportingText = { state.requestError?.let { Text(it) } }
                )

                // Private Toggle
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Make Private",
                        style = MaterialTheme.typography.bodyLarge
                    )
                    Spacer(modifier = Modifier.weight(1f))
                    Switch(
                        checked = state.isPrivate,
                        onCheckedChange = { viewModel.updateIsPrivate(it) }
                    )
                }

                if (state.isPrivate) {
                    Text(
                        text = "Only admins will be able to see this prayer request",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                // Submit Button
                Button(
                    onClick = { viewModel.submitPrayerRequest() },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 16.dp),
                    enabled = !state.isLoading && state.canSubmit
                ) {
                    if (state.isLoading) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(24.dp),
                            color = MaterialTheme.colorScheme.onPrimary
                        )
                    } else {
                        Text("Submit")
                    }
                }
            }
        }
    }

    // Error Dialog
    if (showError) {
        AlertDialog(
            onDismissRequest = { showError = false },
            title = { Text("Error") },
            text = { Text(state.error ?: "An error occurred. Please try again.") },
            confirmButton = {
                TextButton(onClick = { showError = false }) {
                    Text("OK")
                }
            }
        )
    }

    // Success Dialog
    if (showSuccess) {
        AlertDialog(
            onDismissRequest = {
                showSuccess = false
                viewModel.resetState()
                onDismiss()
            },
            title = { Text("Success") },
            text = { Text("Your prayer request has been submitted successfully.") },
            confirmButton = {
                TextButton(
                    onClick = {
                        showSuccess = false
                        viewModel.resetState()
                        onDismiss()
                    }
                ) {
                    Text("OK")
                }
            }
        )
    }
}
