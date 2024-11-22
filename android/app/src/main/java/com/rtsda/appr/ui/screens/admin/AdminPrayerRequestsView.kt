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
import androidx.compose.material.ExperimentalMaterialApi
import androidx.compose.material.pullrefresh.PullRefreshIndicator
import androidx.compose.material.pullrefresh.pullRefresh
import androidx.compose.material.pullrefresh.rememberPullRefreshState
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.rtsda.appr.data.model.PrayerRequest
import com.rtsda.appr.data.model.RequestStatus
import com.rtsda.appr.data.model.RequestType
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class, ExperimentalMaterialApi::class)
@Composable
fun AdminPrayerRequestsView(
    viewModel: AdminPrayerRequestsViewModel,
    onNavigateBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    var showFilters by remember { mutableStateOf(false) }
    var selectedType by remember { mutableStateOf<RequestType?>(null) }
    var showPrayedForOnly by remember { mutableStateOf(false) }
    var showPrivateOnly by remember { mutableStateOf(false) }
    var searchText by remember { mutableStateOf("") }

    val filteredRequests = uiState.prayerRequests.filter { request ->
        val matchesSearch = searchText.isEmpty() || 
            request.name.contains(searchText, ignoreCase = true) ||
            request.email.contains(searchText, ignoreCase = true) ||
            request.request.contains(searchText, ignoreCase = true)
        
        val matchesType = selectedType == null || request.requestType == selectedType
        val matchesPrayedFor = !showPrayedForOnly || request.status == RequestStatus.PRAYED
        val matchesPrivate = !showPrivateOnly || request.isPrivate
        
        matchesSearch && matchesType && matchesPrayedFor && matchesPrivate
    }

    val pullRefreshState = rememberPullRefreshState(
        refreshing = uiState.isLoading,
        onRefresh = { viewModel.loadPrayerRequests() }
    )

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Prayer Requests") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    IconButton(onClick = { showFilters = true }) {
                        Icon(Icons.Default.FilterList, contentDescription = "Filter")
                    }
                }
            )
        },
        modifier = modifier.fillMaxSize()
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Search Bar
            OutlinedTextField(
                value = searchText,
                onValueChange = { searchText = it },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                placeholder = { Text("Search requests") },
                leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) }
            )

            // Filters Section
            if (showFilters) {
                FiltersSection(
                    selectedType = selectedType,
                    showPrayedForOnly = showPrayedForOnly,
                    showPrivateOnly = showPrivateOnly,
                    onTypeSelected = { selectedType = it },
                    onPrayedForChanged = { showPrayedForOnly = it },
                    onPrivateChanged = { showPrivateOnly = it }
                )
            }

            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .pullRefresh(pullRefreshState)
            ) {
                when {
                    uiState.error != null -> {
                        Box(
                            modifier = Modifier.fillMaxSize(),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = uiState.error ?: "An error occurred",
                                style = MaterialTheme.typography.bodyLarge,
                                color = MaterialTheme.colorScheme.error
                            )
                        }
                    }
                    filteredRequests.isEmpty() && !uiState.isLoading -> {
                        Box(
                            modifier = Modifier.fillMaxSize(),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = "No prayer requests found",
                                style = MaterialTheme.typography.bodyLarge
                            )
                        }
                    }
                    else -> {
                        LazyColumn(
                            modifier = Modifier.fillMaxSize(),
                            contentPadding = PaddingValues(16.dp),
                            verticalArrangement = Arrangement.spacedBy(16.dp)
                        ) {
                            items(filteredRequests) { request ->
                                PrayerRequestCard(
                                    request = request,
                                    onStatusChange = { newStatus ->
                                        viewModel.updateRequestStatus(request, newStatus)
                                    },
                                    onDelete = {
                                        viewModel.deleteRequest(request)
                                    }
                                )
                            }
                        }
                    }
                }
                PullRefreshIndicator(
                    refreshing = uiState.isLoading,
                    state = pullRefreshState,
                    modifier = Modifier.align(Alignment.TopCenter)
                )
            }
        }
    }
}

@Composable
private fun FiltersSection(
    selectedType: RequestType?,
    showPrayedForOnly: Boolean,
    showPrivateOnly: Boolean,
    onTypeSelected: (RequestType?) -> Unit,
    onPrayedForChanged: (Boolean) -> Unit,
    onPrivateChanged: (Boolean) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
    ) {
        // Type Filter
        Text(
            text = "Filter by Type",
            style = MaterialTheme.typography.titleMedium,
            modifier = Modifier.padding(vertical = 8.dp)
        )
        Row(
            modifier = Modifier.horizontalScroll(rememberScrollState()),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            RequestType.values().forEach { type ->
                FilterChip(
                    selected = selectedType == type,
                    onClick = { onTypeSelected(if (selectedType == type) null else type) },
                    label = { Text(type.toString()) }
                )
            }
        }

        // Status and Privacy Filters
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 8.dp),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            FilterChip(
                selected = showPrayedForOnly,
                onClick = { onPrayedForChanged(!showPrayedForOnly) },
                label = { Text("Prayed For") }
            )
            FilterChip(
                selected = showPrivateOnly,
                onClick = { onPrivateChanged(!showPrivateOnly) },
                label = { Text("Private Only") }
            )
        }
    }
}

@Composable
private fun PrayerRequestCard(
    request: PrayerRequest,
    onStatusChange: (RequestStatus) -> Unit,
    onDelete: () -> Unit
) {
    var showDeleteDialog by remember { mutableStateOf(false) }
    var expanded by remember { mutableStateOf(false) }
    
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { expanded = !expanded }
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
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
                        contentDescription = "Private",
                        tint = MaterialTheme.colorScheme.secondary
                    )
                }
            }
            
            Text(
                text = request.request,
                maxLines = if (expanded) Int.MAX_VALUE else 2,
                overflow = TextOverflow.Ellipsis,
                style = MaterialTheme.typography.bodyMedium
            )
            
            if (expanded) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Default.Email, contentDescription = null)
                    Spacer(Modifier.width(8.dp))
                    Text(request.email)
                }
                
                if (request.phone.isNotEmpty()) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.Phone, contentDescription = null)
                        Spacer(Modifier.width(8.dp))
                        Text(request.phone)
                    }
                }
                
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text("Type: ${request.requestType}")
                }
                
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Status Menu
                    Box {
                        var showStatusMenu by remember { mutableStateOf(false) }
                        TextButton(onClick = { showStatusMenu = true }) {
                            Text("Status: ${request.status}")
                        }
                        DropdownMenu(
                            expanded = showStatusMenu,
                            onDismissRequest = { showStatusMenu = false }
                        ) {
                            RequestStatus.values().forEach { status ->
                                DropdownMenuItem(
                                    text = { Text(status.toString()) },
                                    onClick = {
                                        onStatusChange(status)
                                        showStatusMenu = false
                                    }
                                )
                            }
                        }
                    }
                    
                    // Delete Button
                    IconButton(onClick = { showDeleteDialog = true }) {
                        Icon(
                            Icons.Default.Delete,
                            contentDescription = "Delete",
                            tint = MaterialTheme.colorScheme.error
                        )
                    }
                }
            }
        }
    }
    
    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { Text("Delete Prayer Request") },
            text = { Text("Are you sure you want to delete this prayer request?") },
            confirmButton = {
                TextButton(
                    onClick = {
                        onDelete()
                        showDeleteDialog = false
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
