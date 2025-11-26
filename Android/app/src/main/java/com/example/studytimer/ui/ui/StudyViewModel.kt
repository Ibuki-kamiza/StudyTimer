package com.example.studytimer.model

import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.compose.*

enum class BottomTab(val label: String, val icon: androidx.compose.ui.graphics.vector.ImageVector) {
    Timer("タイマー", Icons.Filled.AccessTime),
    Home("ホーム", Icons.Filled.Home),
    Record("記録", Icons.Filled.Edit),
    Profile("プロフィール", Icons.Filled.Person)
}

@Composable
fun MainScreen(vm: StudyViewModel = viewModel()) {
    val nav = rememberNavController()
    var tab by remember { mutableStateOf(BottomTab.Home) }

    Scaffold(
        bottomBar = {
            NavigationBar {
                BottomTab.entries.forEach { t ->
                    NavigationBarItem(
                        selected = tab == t,
                        onClick = {
                            tab = t
                            nav.navigate(t.name) {
                                popUpTo(nav.graph.startDestinationId) { saveState = true }
                                launchSingleTop = true
                                restoreState = true
                            }
                        },
                        icon = { Icon(t.icon, contentDescription = t.label) },
                        label = { Text(t.label) }
                    )
                }
            }
        }
    ) { padding ->
        NavHost(
            navController = nav,
            startDestination = BottomTab.Home.name,
            modifier = Modifier.padding(padding)
        ) {
            composable(BottomTab.Home.name) { com.example.studytimer.ui.home.HomeScreen(vm) }
            composable(BottomTab.Timer.name) { com.example.studytimer.ui.timer.TimerScreen(vm) }
            composable(BottomTab.Record.name) { com.example.studytimer.ui.record.RecordScreen(vm) }
            composable(BottomTab.Profile.name) { com.example.studytimer.ui.profile.ProfileScreen(vm) }
        }
    }
}
