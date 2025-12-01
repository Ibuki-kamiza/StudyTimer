package com.example.studytimer.model

import androidx.lifecycle.ViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import java.time.LocalDate
import java.util.UUID

class StudyViewModel : ViewModel() {

    // --- プロフィール ---
    val profileName = MutableStateFlow("なまえ さん")
    val targetSchool = MutableStateFlow("〇〇高校")
    val targetQualifications = MutableStateFlow("")

    // タイマー背景（画像URIを文字列で保持する想定）
    val timerBackgroundUri = MutableStateFlow<String?>(null)

    // --- 大事な日 ---
    val importantTitle = MutableStateFlow("")
    val importantDate = MutableStateFlow(LocalDate.now().plusDays(30))

    // --- 目標（分）---
    val dailyGoalMinutes = MutableStateFlow(120)
    val weeklyGoalMinutes = MutableStateFlow(10 * 60)
    val monthlyGoalMinutes = MutableStateFlow(40 * 60)

    // --- 学習記録 ---
    val studyMinutesByDay = MutableStateFlow<Map<Int, Int>>(emptyMap())
    val materials = MutableStateFlow<List<StudyMaterial>>(emptyList())

    fun addStudyMinutes(minutes: Int, date: LocalDate = LocalDate.now()) {
        if (minutes <= 0) return
        val day = date.dayOfMonth
        val map = studyMinutesByDay.value.toMutableMap()
        map[day] = (map[day] ?: 0) + minutes
        studyMinutesByDay.value = map
    }

    fun addMaterial(title: String, comment: String = "", finishedAt: LocalDate = LocalDate.now()) {
        val list = materials.value.toMutableList()
        list.add(0, StudyMaterial(title = title, finishedAt = finishedAt, comment = comment))
        materials.value = list
    }

    fun removeMaterial(material: StudyMaterial) {
        materials.value = materials.value.filterNot { it.id == material.id }
    }
}
