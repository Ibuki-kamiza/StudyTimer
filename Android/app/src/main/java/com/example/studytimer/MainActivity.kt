package com.example.studytimer

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels   // ← これを追加
import com.example.studytimer.model.StudyViewModel
import com.example.studytimer.ui.MainScreen
import com.example.studytimer.ui.theme.StudyTimerTheme

class MainActivity : ComponentActivity() {

    // iOS の @EnvironmentObject var store に相当
    private val vm: StudyViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            StudyTimerTheme {
                MainScreen(vm)   // ← ViewModel を渡す
            }
        }
    }
}
