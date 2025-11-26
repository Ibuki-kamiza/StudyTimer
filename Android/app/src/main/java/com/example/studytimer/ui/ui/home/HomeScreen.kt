package com.example.studytimer.ui.home

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.*
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.example.studytimer.StudyViewModel
import java.time.*
import java.time.format.TextStyle
import java.util.*

@Composable
fun HomeScreen(vm: StudyViewModel) {

    var displayedMonth by remember { mutableStateOf(YearMonth.now()) }

    val today = LocalDate.now()
    val todayMinutes = vm.minutesOn(today)

    val monthlyTotalMinutes = vm.monthlyTotalMinutes(displayedMonth)

    val weekStart = today.with(DayOfWeek.MONDAY)
    val weeklyTotalMinutes = vm.weeklyTotalMinutes(weekStart)

    val monthlyProgress = remember(monthlyTotalMinutes, vm.monthlyGoalMinutes) {
        if (vm.monthlyGoalMinutes == 0) 0f
        else (monthlyTotalMinutes.toFloat() / vm.monthlyGoalMinutes).coerceIn(0f,1f)
    }
    val weeklyProgress = remember(weeklyTotalMinutes, vm.weeklyGoalMinutes) {
        if (vm.weeklyGoalMinutes == 0) 0f
        else (weeklyTotalMinutes.toFloat() / vm.weeklyGoalMinutes).coerceIn(0f,1f)
    }

    val daysToImportant = remember(vm.importantDate) {
        Duration.between(today.atStartOfDay(), vm.importantDate.atStartOfDay()).toDays().toInt()
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(18.dp)
    ) {

        // ① 今日の予定/実績
        CardSection {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Column {
                    Text("今日の勉強予定時間", style = MaterialTheme.typography.labelMedium)
                    val h = vm.dailyGoalMinutes / 60
                    val m = vm.dailyGoalMinutes % 60
                    Text("${h}時間${m.toString().padStart(2,'0')}分", fontWeight = FontWeight.Bold)
                }
                Column {
                    Text("実績", style = MaterialTheme.typography.labelMedium)
                    Text("${todayMinutes/60}時間${(todayMinutes%60).toString().padStart(2,'0')}分", fontWeight = FontWeight.Bold)
                }
            }
        }

        // ② 月カレンダー（学習時間も表示）
        CardSection {
            CalendarHeader(
                displayedMonth,
                onPrev = { displayedMonth = displayedMonth.minusMonths(1) },
                onNext = { displayedMonth = displayedMonth.plusMonths(1) }
            )
            CalendarGrid(displayedMonth, vm)
        }

        // ③ カウントダウン
        CardSection {
            Text("大事な日のカウントダウン", fontWeight = FontWeight.Bold)
            Spacer(Modifier.height(6.dp))
            Row {
                Text("${vm.importantTitle}まであと ")
                Text("${maxOf(0, daysToImportant)}日", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
            }
        }

        // ④ 目標（週間/月間）
        CardSection {
            Text("目標", fontWeight = FontWeight.Bold)
            Spacer(Modifier.height(8.dp))

            GoalRow("今月の目標：${vm.monthlyGoalMinutes/60}時間", monthlyProgress)
            GoalRow("今週の目標：${vm.weeklyGoalMinutes/60}時間", weeklyProgress)
        }

        // ⑤ 円グラフは後で（Swift側のカテゴリ管理が揃ったら移植）
        CardSection {
            Text("科目別学習割合（後で移植）")
        }
    }
}

@Composable private fun CardSection(content: @Composable ColumnScope.() -> Unit) {
    Surface(
        tonalElevation = 1.dp,
        shape = RoundedCornerShape(16.dp),
        color = Color(0xFFF2F2F2),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(Modifier.padding(14.dp), content = content)
    }
}

@Composable private fun GoalRow(label: String, progress: Float) {
    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        Text(label)
        Spacer(Modifier.weight(1f))
        LinearProgressIndicator(progress, Modifier.width(120.dp))
        Spacer(Modifier.width(8.dp))
        Icon(
            imageVector = if (progress >= 1f) Icons.Filled.CheckBox else Icons.Filled.CheckBoxOutlineBlank,
            contentDescription = null
        )
    }
}

@Composable private fun CalendarHeader(
    displayedMonth: YearMonth,
    onPrev: () -> Unit,
    onNext: () -> Unit
) {
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
        IconButton(onClick = onPrev) { Icon(Icons.Filled.ChevronLeft, null) }
        Text("${displayedMonth.year}年${displayedMonth.monthValue}月", fontWeight = FontWeight.Bold)
        IconButton(onClick = onNext) { Icon(Icons.Filled.ChevronRight, null) }
    }
}

@Composable private fun CalendarGrid(month: YearMonth, vm: StudyViewModel) {
    val firstDay = month.atDay(1)
    val firstWeekdayIndex = (firstDay.dayOfWeek.value % 7) // Sun=0

    val daysInMonth = month.lengthOfMonth()

    val cells = buildList {
        repeat(firstWeekdayIndex) { add(null) }
        for (d in 1..daysInMonth) add(d)
    }

    // weekday labels
    val weekdays = listOf("S","M","T","W","T","F","S")
    LazyVerticalGrid(columns = GridCells.Fixed(7), modifier = Modifier.fillMaxWidth()) {
        items(weekdays) { w ->
            Text(w, modifier = Modifier.fillMaxWidth(), textAlign = androidx.compose.ui.text.style.TextAlign.Center)
        }
        items(cells) { day ->
            if (day == null) {
                Box(Modifier.height(52.dp))
            } else {
                val date = month.atDay(day)
                val min = vm.minutesOn(date)
                Column(
                    Modifier
                        .padding(2.dp)
                        .background(Color(0xFFE8E8E8), RoundedCornerShape(6.dp))
                        .padding(6.dp)
                        .height(52.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text("$day")
                    Text(
                        "${(min/60).toString().padStart(2,'0')}:${(min%60).toString().padStart(2,'0')}",
                        style = MaterialTheme.typography.labelSmall
                    )
                }
            }
        }
    }
}
