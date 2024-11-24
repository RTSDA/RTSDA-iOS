package com.rtsda.appr.ui.screens.admin

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.rtsda.appr.data.model.PrayerRequest
import com.rtsda.appr.data.model.RequestStatus
import com.rtsda.appr.data.model.RequestType
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AdminPrayerRequestsView(
    viewModel: AdminPrayerRequestsViewModel,
    onNavigateBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    var showFilters by remember { mutableStateOf(false) }
    var searchText by remember { mutableStateOf("") }
    var showDeleteDialog by remember { mutableStateOf(false) }
    var requestToDelete by remember { mutableStateOf<PrayerRequest?>(null) }

    val filteredRequests = uiState.requests.filter { request ->
        val matchesSearch = searchText.isEmpty() ||
            request.name.contains(searchText, ignoreCase = true) ||
            request.email.contains(searchText, ignoreCase = true) ||
            request.request.contains(searchText, ignoreCase = true)

        val matchesType = uiState.selectedType == null || request.requestType == uiState.selectedType
        val matchesApproved = !uiState.showApprovedOnly || request.status == RequestStatus.APPROVED
        val matchesPrivate = !uiState.showPrivateOnly || request.isPrivate

        matchesSearch && matchesType && matchesApproved && matchesPrivate
    }

    Scaffold(
        topBar = {
            Column {
                TopAppBar(
                    title = { Text("Prayer Requests") },
                    navigationIcon = {
                        IconButton(onClick = onNavigateBack) {
                            Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                        }
                    },
                    actions = {
                        IconButton(onClick = { showFilters = true }) {
                            Icon(
                                imageVector = Icons.Default.FilterList,
                                contentDescription = "Filter"
                            )
                        }
                    }
                )
                SearchBar(
                    query = searchText,
                    onQueryChange = { searchText = it },
                    onSearch = { },
                    active = false,
                    onActiveChange = { },
                    modifier = Modifier.fillMaxWidth(),
                    placeholder = { Text("Search requests") },
                    leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) }
                ) { }
            }
        }
    ) { padding ->
        Box(modifier = modifier.padding(padding)) {
            if (uiState.isLoading) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator()
                }
            } else if (uiState.requests.isEmpty()) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.PriorityHigh,
                            contentDescription = null,
                            modifier = Modifier.size(48.dp)
                        )
                        Text(
                            text = "No Prayer Requests",
                            style = MaterialTheme.typography.headlineSmall
                        )
                        Text(
                            text = "Prayer requests will appear here",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    item {
                        FiltersSection(
                            selectedType = uiState.selectedType,
                            showApprovedOnly = uiState.showApprovedOnly,
                            showPrivateOnly = uiState.showPrivateOnly,
                            onTypeSelected = { viewModel.updateSelectedType(it) },
                            onApprovedChanged = { viewModel.updateShowApprovedOnly(it) },
                            onPrivateChanged = { viewModel.updateShowPrivateOnly(it) }
                        )
                    }

                    items(
                        items = filteredRequests,
                        key = { it.id }
                    ) { request ->
                        SwipeToDismiss(
                            request = request,
                            onDismiss = {
                                requestToDelete = request
                                showDeleteDialog = true
                            }
                        ) {
                            PrayerRequestCard(
                                request = request,
                                onStatusChange = { newStatus ->
                                    viewModel.updateRequestStatus(request.id, newStatus)
                                }
                            )
                        }
                    }
                }
            }

            if (showFilters) {
                FilterSheet(
                    selectedType = uiState.selectedType,
                    onTypeSelected = { viewModel.updateSelectedType(it) },
                    onDismiss = { showFilters = false }
                )
            }

            if (showDeleteDialog) {
                AlertDialog(
                    onDismissRequest = { showDeleteDialog = false },
                    title = { Text("Delete Request") },
                    text = { Text("Are you sure you want to delete this prayer request?") },
                    confirmButton = {
                        TextButton(
                            onClick = {
                                requestToDelete?.let { viewModel.deleteRequest(it.id) }
                                showDeleteDialog = false
                                requestToDelete = null
                            }
                        ) {
                            Text("Delete", color = MaterialTheme.colorScheme.error)
                        }
                    },
                    dismissButton = {
                        TextButton(onClick = { showDeleteDialog = false }) {
                            Text("Cancel")
                        }
                    }
                )
            }
        }
    }
}

@Composable
private fun FiltersSection(
    selectedType: RequestType?,
    showApprovedOnly: Boolean,
    showPrivateOnly: Boolean,
    onTypeSelected: (RequestType?) -> Unit,
    onApprovedChanged: (Boolean) -> Unit,
    onPrivateChanged: (Boolean) -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.fillMaxWidth(),
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Filters",
                    style = MaterialTheme.typography.titleMedium
                )
                if (selectedType != null) {
                    TextButton(onClick = { onTypeSelected(null) }) {
                        Text("Clear")
                    }
                }
            }

            Switch(
                checked = showApprovedOnly,
                onCheckedChange = onApprovedChanged,
                modifier = Modifier.fillMaxWidth(),
                thumbContent = if (showApprovedOnly) {
                    { Icon(Icons.Default.Check, contentDescription = null) }
                } else null
            )
            Text(
                text = "Show Approved Only",
                style = MaterialTheme.typography.bodyMedium
            )

            Switch(
                checked = showPrivateOnly,
                onCheckedChange = onPrivateChanged,
                modifier = Modifier.fillMaxWidth(),
                thumbContent = if (showPrivateOnly) {
                    { Icon(Icons.Default.Check, contentDescription = null) }
                } else null
            )
            Text(
                text = "Show Private Only",
                style = MaterialTheme.typography.bodyMedium
            )

            if (selectedType != null) {
                Text(
                    text = "Type: ${selectedType.name}",
                    style = MaterialTheme.typography.bodyMedium
                )
            }
        }
    }
}

@Composable
private fun FilterSheet(
    selectedType: RequestType?,
    onTypeSelected: (RequestType) -> Unit,
    onDismiss: () -> Unit
) {
    ModalBottomSheet(
        onDismissRequest = onDismiss
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Text(
                text = "Request Type",
                style = MaterialTheme.typography.titleLarge,
                modifier = Modifier.padding(bottom = 16.dp)
            )

            RequestType.values().forEach { type ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { onTypeSelected(type) }
                        .padding(vertical = 12.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = type.name,
                        style = MaterialTheme.typography.bodyLarge
                    )
                    if (type == selectedType) {
                        Icon(
                            imageVector = Icons.Default.Check,
                            contentDescription = "Selected"
                        )
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SwipeToDismiss(
    request: PrayerRequest,
    onDismiss: () -> Unit,
    content: @Composable () -> Unit
) {
    val dismissState = rememberDismissState(
        confirmValueChange = { dismissValue ->
            if (dismissValue == DismissValue.DismissedToEnd || dismissValue == DismissValue.DismissedToStart) {
                onDismiss()
                true
            } else {
                false
            }
        }
    )

    SwipeToDismiss(
        state = dismissState,
        background = {
            val color = MaterialTheme.colorScheme.error
            val direction = dismissState.dismissDirection

            Row(
                modifier = Modifier
                    .fillMaxSize()
                    .background(color)
                    .padding(horizontal = 20.dp),
                horizontalArrangement = if (direction == DismissDirection.StartToEnd) {
                    Arrangement.Start
                } else {
                    Arrangement.End
                },
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.Delete,
                    contentDescription = "Delete",
                    tint = MaterialTheme.colorScheme.onError
                )
            }
        },
        dismissContent = { content() }
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun PrayerRequestCard(
    request: PrayerRequest,
    onStatusChange: (RequestStatus) -> Unit,
    modifier: Modifier = Modifier
) {
    ElevatedCard(
        modifier = modifier.fillMaxWidth(),
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = request.name,
                    style = MaterialTheme.typography.titleMedium
                )
                if (request.isPrivate) {
                    Icon(
                        imageVector = Icons.Default.Lock,
                        contentDescription = "Private"
                    )
                }
            }

            Text(
                text = request.email,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Text(
                text = request.request,
                style = MaterialTheme.typography.bodyMedium,
                maxLines = 3,
                overflow = TextOverflow.Ellipsis
            )

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = SimpleDateFormat("MMM d, yyyy", Locale.getDefault())
                        .format(request.timestamp.toDate()),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    RequestStatus.values().forEach { status ->
                        FilterChip(
                            selected = request.status == status,
                            onClick = { onStatusChange(status) },
                            label = { Text(status.name) },
                            leadingIcon = if (request.status == status) {
                                { Icon(Icons.Default.Check, contentDescription = null) }
                            } else null
                        )
                    }
                }
            }
        }
    }
}
