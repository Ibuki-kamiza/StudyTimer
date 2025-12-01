package com.example.studytimer.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccessTime
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import com.example.studytimer.model.StudyViewModel
import com.example.studytimer.ui.home.HomeScreen
import com.example.studytimer.ui.profile.ProfileScreen
import com.example.studytimer.ui.record.RecordScreen
import com.example.studytimer.ui.timer.TimerScreen

@Composable
fun MainScreen(vm: StudyViewModel) {
    var selectedTab by remember { mutableStateOf(BottomTab.Timer) }

    Scaffold(
        bottomBar = {
            NavigationBar {
                BottomTab.values().forEach { tab ->
                    NavigationBarItem(
                        selected = selectedTab == tab,
                        onClick = { selectedTab = tab },
                        icon = { Icon(tab.icon, contentDescription = tab.label) },
                        label = { Text(tab.label) }
                    )
                }
            }
        }
    ) { innerPadding ->
        Box(Modifier.padding(innerPadding)) {
            when (selectedTab) {
                BottomTab.Timer   -> TimerScreen(vm)
                BottomTab.Home    -> HomeScreen(vm)
                BottomTab.Record  -> RecordScreen(vm)
                BottomTab.Profile -> ProfileScreen(vm)
            }
        }
    }
}

enum class BottomTab(val label: String, val icon: androidx.compose.ui.graphics.vector.ImageVector) {
    Timer("タイマー", Icons.Filled.AccessTime),
    Home("ホーム", Icons.Filled.Home),
    Record("記録", Icons.Filled.Edit),
    Profile("プロフィール", Icons.Filled.Person)
}
