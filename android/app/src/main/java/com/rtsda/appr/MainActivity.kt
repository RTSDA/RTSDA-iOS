package com.rtsda.appr

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.addCallback
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.dialog
import androidx.navigation.compose.rememberNavController
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.rtsda.appr.navigation.NavigationItem
import com.rtsda.appr.navigation.bottomNavItems
import com.rtsda.appr.ui.screens.*
import com.rtsda.appr.ui.screens.admin.*
import com.rtsda.appr.ui.viewmodels.AdminEventViewModel
import com.rtsda.appr.ui.theme.RTSDATheme
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        
        setContent {
            RTSDATheme {
                val navController = rememberNavController()
                val navBackStackEntry by navController.currentBackStackEntryAsState()
                val currentDestination = navBackStackEntry?.destination

                // Handle system back button
                val onBackPressedCallback = remember {
                    onBackPressedDispatcher.addCallback(this) {
                        if (navController.previousBackStackEntry != null) {
                            navController.navigateUp()
                        } else {
                            finish()
                        }
                    }
                }

                DisposableEffect(Unit) {
                    onDispose {
                        onBackPressedCallback.remove()
                    }
                }

                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    Scaffold(
                        bottomBar = {
                            NavigationBar {
                                bottomNavItems.forEach { item ->
                                    NavigationBarItem(
                                        icon = { Icon(item.icon, contentDescription = item.title) },
                                        label = { 
                                            Text(
                                                text = item.title,
                                                maxLines = 1,
                                                softWrap = false,
                                                style = MaterialTheme.typography.labelSmall
                                            ) 
                                        },
                                        selected = currentDestination?.hierarchy?.any { it.route == item.route } == true,
                                        onClick = {
                                            navController.navigate(item.route) {
                                                popUpTo(navController.graph.findStartDestination().id) {
                                                    saveState = true
                                                }
                                                launchSingleTop = true
                                                restoreState = true
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    ) { paddingValues ->
                        Box(modifier = Modifier.padding(paddingValues)) {
                            NavHost(navController = navController, startDestination = NavigationItem.Home.route) {
                                composable(NavigationItem.Home.route) { HomeScreen(navController) }
                                composable(NavigationItem.PrayerRequest.route) { 
                                    PrayerRequestScreen(
                                        onDismiss = { navController.navigateUp() }
                                    )
                                }
                                composable(NavigationItem.Bulletins.route) {
                                    BulletinScreen()
                                }
                                composable(NavigationItem.Sermons.route) {
                                    MessagesScreen(
                                        onVideoClick = { videoId ->
                                            navController.navigate("video/$videoId")
                                        }
                                    )
                                }
                                composable(NavigationItem.Events.route) {
                                    EventsScreen()
                                }
                                composable(NavigationItem.More.route) {
                                    MoreScreen(
                                        onNavigateToPrayerRequests = {
                                            navController.navigate(NavigationItem.PrayerRequest.route)
                                        },
                                        onNavigateToGiveOnline = {
                                            navController.navigate("give_online")
                                        },
                                        onNavigateToAboutUs = {
                                            navController.navigate("about_us")
                                        },
                                        onNavigateToContactUs = {
                                            navController.navigate("contact_us")
                                        },
                                        onNavigateToSocialMedia = {
                                            navController.navigate("social_media")
                                        },
                                        onNavigateToResources = {
                                            navController.navigate("resources")
                                        },
                                        onNavigateToAdmin = {
                                            navController.navigate("admin") {
                                                launchSingleTop = true
                                            }
                                        }
                                    )
                                }
                                composable("give_online") {
                                    GiveOnlineScreen(
                                        onDismiss = { navController.navigateUp() }
                                    )
                                }
                                composable("about_us") {
                                    AboutUsScreen(
                                        onDismiss = { navController.navigateUp() }
                                    )
                                }
                                composable("contact_us") {
                                    ContactUsScreen(
                                        onDismiss = { navController.navigateUp() }
                                    )
                                }
                                composable("social_media") {
                                    SocialMediaScreen(
                                        onDismiss = { navController.navigateUp() }
                                    )
                                }
                                composable("resources") {
                                    ResourcesScreen(
                                        onDismiss = { navController.navigateUp() }
                                    )
                                }
                                composable("admin") {
                                    AdminLoginScreen(
                                        onDismiss = { navController.navigateUp() },
                                        onNavigateToEvents = { navController.navigate("admin/events") },
                                        onNavigateToPrayerRequests = { navController.navigate("admin/prayer_requests") }
                                    )
                                }
                                composable("admin/events") {
                                    val viewModel: AdminEventViewModel = hiltViewModel()
                                    AdminEventView(
                                        viewModel = viewModel,
                                        onNavigateBack = { navController.navigateUp() },
                                        onAddEvent = { 
                                            viewModel.clearCache() // Clear any existing event data
                                            navController.navigate("admin/events/form") {
                                                popUpTo("admin/events")
                                            }
                                        },
                                        onEditEvent = { eventId -> 
                                            navController.navigate("admin/events/form?eventId=$eventId") {
                                                popUpTo("admin/events")
                                            }
                                        }
                                    )
                                }
                                dialog(
                                    route = "admin/events/form?eventId={eventId}",
                                    arguments = listOf(
                                        navArgument("eventId") {
                                            type = NavType.StringType
                                            nullable = true
                                            defaultValue = null
                                        }
                                    )
                                ) { backStackEntry ->
                                    val parentEntry = remember(backStackEntry) {
                                        navController.getBackStackEntry("admin/events")
                                    }
                                    val eventId = backStackEntry.arguments?.getString("eventId")
                                    val viewModel = hiltViewModel<AdminEventViewModel>(parentEntry)
                                    
                                    AdminEventFormView(
                                        viewModel = viewModel,
                                        onDismiss = { navController.navigateUp() },
                                        eventId = eventId
                                    )
                                }
                                composable("admin/prayer_requests") {
                                    AdminPrayerRequestsView(
                                        viewModel = hiltViewModel(),
                                        onNavigateBack = { navController.navigateUp() }
                                    )
                                }
                                composable("video/{videoId}") { backStackEntry ->
                                    val videoId = backStackEntry.arguments?.getString("videoId") ?: return@composable
                                    VideoPlayerScreen(
                                        videoId = videoId,
                                        onBackClick = { navController.navigateUp() }
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}