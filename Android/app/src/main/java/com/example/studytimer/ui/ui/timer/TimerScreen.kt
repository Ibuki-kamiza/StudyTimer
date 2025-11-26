package com.example.studytimer.ui.timer

import android.media.RingtoneManager
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.*
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.*
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.dp
import com.example.studytimer.StudyViewModel
import kotlinx.coroutines.delay

private enum class Phase { Focus, Break }

@Composable
fun TimerScreen(vm: StudyViewModel) {

    var phase by remember { mutableStateOf(Phase.Focus) }
    var remainingSec by remember { mutableStateOf(25 * 60) }
    var isRunning by remember { mutableStateOf(false) }
    var focusCount by remember { mutableStateOf(0) }

    // 背景はプロフィール画像を使う
    val bgBitmap = vm.profileImageBitmap

    LaunchedEffect(isRunning, phase) {
        if (!isRunning) return@LaunchedEffect
        while (isRunning && remainingSec > 0) {
            delay(1000)
            remainingSec--
        }
        if (isRunning && remainingSec == 0) {
            // 終了音
            runCatching {
                val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                RingtoneManager.getRingtone(LocalContext.current, uri).play()
            }
            isRunning = false

            if (phase == Phase.Focus) {
                focusCount++
                phase = Phase.Break
                remainingSec = 5 * 60
            } else {
                phase = Phase.Focus
                remainingSec = 25 * 60
            }
        }
    }

    Box(Modifier.fillMaxSize()) {
        // 背景
        if (bgBitmap != null) {
            Image(
                bitmap = bgBitmap.asImageBitmap(),
                contentDescription = null,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop
            )
            Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.25f)))
        } else {
            Box(Modifier.fillMaxSize().background(Color(0xFFF6F6F6)))
        }

        Column(
            Modifier.fillMaxSize().padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {

            Text(
                if (phase == Phase.Focus) "集中 25分" else "休憩 5分",
                style = MaterialTheme.typography.titleLarge,
                color = Color.White
            )

            Spacer(Modifier.height(16.dp))

            val mm = remainingSec / 60
            val ss = remainingSec % 60

            Text(
                "${mm.toString().padStart(2,'0')}:${ss.toString().padStart(2,'0')}",
                style = MaterialTheme.typography.displayLarge,
                color = Color.White
            )

            Spacer(Modifier.height(16.dp))

            // ◯で回数表示（最大4つ表示）
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                repeat(4) { idx ->
                    val filled = idx < (focusCount % 4)
                    Box(
                        Modifier.size(12.dp)
                            .clip(CircleShape)
                            .background(if (filled) Color.White else Color.White.copy(alpha = 0.35f))
                    )
                }
            }

            Spacer(Modifier.height(26.dp))

            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Button(onClick = { isRunning = !isRunning }) {
                    Text(if (isRunning) "一時停止" else "スタート")
                }
                OutlinedButton(onClick = {
                    isRunning = false
                    phase = Phase.Focus
                    remainingSec = 25 * 60
                    focusCount = 0
                }) {
                    Text("リセット")
                }
            }
        }
    }
}
