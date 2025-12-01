package com.example.studytimer.ui.timer

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.studytimer.model.StudyViewModel
import kotlinx.coroutines.delay

enum class Phase { FOCUS, BREAK }

@Composable
fun TimerScreen(vm: StudyViewModel, modifier: Modifier = Modifier) {

    var phase by remember { mutableStateOf(Phase.FOCUS) }
    var isRunning by remember { mutableStateOf(false) }
    var remaining by remember { mutableStateOf(25 * 60) }
    var focusCount by remember { mutableStateOf(0) }

    // 1秒ごとに残り時間を減らす
    LaunchedEffect(isRunning, phase) {
        while (isRunning) {
            delay(1000)
            if (remaining > 0) {
                remaining--
            } else {
                when (phase) {
                    Phase.FOCUS -> {
                        focusCount++
                        phase = Phase.BREAK
                        remaining = 5 * 60
                    }
                    Phase.BREAK -> {
                        phase = Phase.FOCUS
                        remaining = 25 * 60
                    }
                }
            }
        }
    }

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    colors = listOf(
                        Color(0xFFFACB65),
                        Color(0xFFF07A63),
                    )
                )
            ),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
            modifier = Modifier.padding(24.dp)
        ) {
            // 状態テキスト
            Text(
                text = if (phase == Phase.FOCUS) "集中タイム" else "休憩タイム",
                fontSize = 20.sp,
                color = Color.White.copy(alpha = 0.8f)
            )

            Spacer(Modifier.height(8.dp))

            // 残り時間
            Text(
                text = formatTime(remaining),
                fontSize = 64.sp,
                color = Color.White
            )

            Spacer(Modifier.height(8.dp))

            // ◯ ◯ ◯ ◯
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                repeat(4) { index ->
                    Box(
                        modifier = Modifier
                            .size(16.dp)
                            .clip(CircleShape)
                            .background(
                                if (index < focusCount) Color.White else Color.Transparent
                            )
                            .border(width = 2.dp, color = Color.White.copy(alpha = 0.6f), shape = CircleShape)
                    )
                }
            }

            Spacer(Modifier.height(32.dp))

            Button(
                onClick = { isRunning = !isRunning },
                modifier = Modifier
                    .size(200.dp)
                    .clip(CircleShape)
            ) {
                Text(text = if (isRunning) "ストップ" else "スタート", fontSize = 20.sp)
            }
        }
    }
}

private fun formatTime(sec: Int): String {
    val m = sec / 60
    val s = sec % 60
    return "%02d:%02d".format(m, s)
}
