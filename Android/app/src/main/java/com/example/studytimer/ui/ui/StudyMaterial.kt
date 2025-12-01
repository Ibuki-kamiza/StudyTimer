// app/src/main/java/com/example/studytimer/model/StudyMaterial.kt

package com.example.studytimer.model

import java.time.LocalDate
import java.util.UUID

// Swift の StudyMaterial に相当
data class StudyMaterial(
    val id: String = UUID.randomUUID().toString(),
    val title: String,
    val finishedAt: LocalDate = LocalDate.now(),
    val comment: String = "",
)
