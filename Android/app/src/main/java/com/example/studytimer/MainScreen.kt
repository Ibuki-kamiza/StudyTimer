package com.example.studytimer.ui

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccessTime
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.studytimer.model.StudyViewModel
import com.example.studytimer.ui.home.HomeScreen
import com.example.studytimer.ui.profile.ProfileScreen
import com.example.studytimer.ui.record.RecordScreen
import com.example.studytimer.ui.timer.TimerScreen

@Composable
fun MainScreen(vm: StudyViewModel = viewModel()) {
    var selectedTab by remember { mutableStateOf(0) }

    Scaffold(
        bottomBar = {
            NavigationBar {
                NavigationBarItem(
                    selected = selectedTab == 0,
                    onClick = { selectedTab = 0 },
                    icon = { Icon(Icons.Default.AccessTime, contentDescription = null) },
                    label = { Text("タイマー") }
                )
                NavigationBarItem(
                    selected = selectedTab == 1,
                    onClick = { selectedTab = 1 },
                    icon = { Icon(Icons.Default.Home, contentDescription = null) },
                    label = { Text("ホーム") }
                )
                NavigationBarItem(
                    selected = selectedTab == 2,
                    onClick = { selectedTab = 2 },
                    icon = { Icon(Icons.Default.Edit, contentDescription = null) },
                    label = { Text("記録") }
                )
                NavigationBarItem(
                    selected = selectedTab == 3,
                    onClick = { selectedTab = 3 },
                    icon = { Icon(Icons.Default.Person, contentDescription = null) },
                    label = { Text("プロフィール") }
                )
            }
        }
    ) { innerPadding ->
        when (selectedTab) {
            0 -> TimerScreen(vm, modifier = Modifier.padding(innerPadding))
            1 -> HomeScreen(vm, modifier = Modifier.padding(innerPadding))
            2 -> RecordScreen(vm, modifier = Modifier.padding(innerPadding))
            3 -> ProfileScreen(vm, modifier = Modifier.padding(innerPadding))
        }
    }
}
