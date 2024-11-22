package com.rtsda.appr.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Phone
import androidx.compose.material.icons.filled.Close
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

enum class RequestType {
    PERSONAL,
    FAMILY,
    FRIENDS,
    COMMUNITY,
    OTHER
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PrayerRequestScreen(
    onDismiss: () -> Unit,
    viewModel: PrayerRequestViewModel = hiltViewModel()
) {
    var name by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var phone by remember { mutableStateOf("") }
    var emailError by remember { mutableStateOf<String?>(null) }
    var phoneError by remember { mutableStateOf<String?>(null) }
    var request by remember { mutableStateOf("") }
    var isPrivate by remember { mutableStateOf(false) }
    var selectedType by remember { mutableStateOf(RequestType.PERSONAL) }
    var showError by remember { mutableStateOf(false) }
    var showSuccess by remember { mutableStateOf(false) }
    
    val focusManager = LocalFocusManager.current
    val state by viewModel.state.collectAsState()

    // Email validation function
    fun isValidEmail(email: String): Boolean {
        val emailRegex = "^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}\$"
        return email.matches(emailRegex.toRegex())
    }

    // Phone validation function
    fun isValidPhone(phone: String): Boolean {
        if (phone.isEmpty()) return true // Optional field
        // Allow formats: (123) 456-7890, 123-456-7890, 1234567890
        val phoneRegex = """^(\+\d{1,2}\s?)?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}$""".toRegex()
        return phone.matches(phoneRegex)
    }

    fun formatPhoneNumber(input: String): String {
        // Strip all non-digits
        val digitsOnly = input.replace(Regex("[^0-9]"), "")
        
        // Format as (XXX) XXX-XXXX if we have enough digits
        return when {
            digitsOnly.isEmpty() -> ""
            digitsOnly.length <= 3 -> "(${digitsOnly})"
            digitsOnly.length <= 6 -> "(${digitsOnly.substring(0,3)}) ${digitsOnly.substring(3)}"
            digitsOnly.length <= 10 -> {
                val area = digitsOnly.substring(0,3)
                val prefix = digitsOnly.substring(3,6)
                val number = digitsOnly.substring(6)
                "($area) $prefix-$number"
            }
            else -> {
                // Truncate to 10 digits if longer
                val truncated = digitsOnly.substring(0, 10)
                val area = truncated.substring(0,3)
                val prefix = truncated.substring(3,6)
                val number = truncated.substring(6)
                "($area) $prefix-$number"
            }
        }
    }

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
            // Top Bar
            TopAppBar(
                title = { Text("Prayer Request") },
                navigationIcon = {
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.Close, contentDescription = "Close")
                    }
                }
            )

            // Form Content
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
                        checked = isPrivate,
                        onCheckedChange = { isPrivate = it }
                    )
                }

                if (isPrivate) {
                    Text(
                        text = "Your prayer request will be submitted anonymously",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                // Name Field (only show if not anonymous)
                if (!isPrivate) {
                    OutlinedTextField(
                        value = name,
                        onValueChange = { name = it },
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
                        singleLine = true
                    )
                }

                // Email Field
                OutlinedTextField(
                    value = email,
                    onValueChange = { 
                        email = it
                        emailError = if (it.isNotEmpty() && !isValidEmail(it)) {
                            "Please enter a valid email address"
                        } else null
                    },
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
                    isError = emailError != null,
                    supportingText = { emailError?.let { Text(it) } },
                    singleLine = true
                )

                // Phone Field
                OutlinedTextField(
                    value = phone,
                    onValueChange = { newValue ->
                        phone = formatPhoneNumber(newValue)
                        phoneError = if (!isValidPhone(phone)) "Please enter a valid phone number" else null
                    },
                    label = { Text("Phone (Optional)") },
                    keyboardOptions = KeyboardOptions(
                        keyboardType = KeyboardType.Phone,
                        imeAction = ImeAction.Next
                    ),
                    keyboardActions = KeyboardActions(
                        onNext = { focusManager.moveFocus(FocusDirection.Down) }
                    ),
                    singleLine = true,
                    isError = phoneError != null,
                    supportingText = phoneError?.let { { Text(it) } },
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
                            selected = selectedType == type,
                            onClick = { selectedType = type },
                            label = { Text(type.toString()) },
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Prayer Request Field
                OutlinedTextField(
                    value = request,
                    onValueChange = { request = it },
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
                    )
                )

                // Submit Button
                Button(
                    onClick = {
                        if (
                            (isPrivate || name.isNotEmpty()) && // Name only required if not anonymous
                            (email.isEmpty() || emailError == null) && // Email valid if provided
                            phoneError == null && // Phone valid if provided
                            request.isNotEmpty() // Request is required
                        ) {
                            viewModel.submitPrayerRequest(
                                name = if (isPrivate) "Anonymous" else name,
                                email = email,
                                phone = phone,
                                request = request,
                                isPrivate = isPrivate,
                                requestType = selectedType
                            )
                        }
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 16.dp)
                ) {
                    Text("Submit")
                }
            }
        }
    }

    // Error Dialog
    if (showError) {
        AlertDialog(
            onDismissRequest = { showError = false },
            title = { Text("Error") },
            text = { Text(state.error ?: "Please fill in all required fields.") },
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
            text = { Text("Your prayer request has been submitted.") },
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
