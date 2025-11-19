package com.example.studytimer

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccessTime
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp

// タブの種類
enum class BottomTab(val label: String, val icon: ImageVector) {
    Timer("タイマー", Icons.Filled.AccessTime),   // ← Timer ではなく AccessTime
    Home("ホーム", Icons.Filled.Home),
    Record("記録", Icons.Filled.Edit),
    Profile("プロフィール", Icons.Filled.Person)
}

@Composable
fun MainScreen() {
    var selectedTab by remember { mutableStateOf(BottomTab.Home) }

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
        Box(
            modifier = Modifier
                .padding(innerPadding)
                .fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            when (selectedTab) {
                BottomTab.Timer   -> Text("タイマー画面（これから作る）")
                BottomTab.Home    -> Text("ホーム画面（これから作る）")
                BottomTab.Record  -> Text("記録画面（これから作る）")
                BottomTab.Profile -> Text("プロフィール画面（これから作る）")
            }
        }
    }
}
