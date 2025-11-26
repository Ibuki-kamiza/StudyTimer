package com.example.studytimer.ui.record

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.example.studytimer.StudyViewModel
import java.time.LocalDate

@Composable
fun RecordScreen(vm: StudyViewModel) {

    var showStudyDialog by remember { mutableStateOf(false) }
    var showMaterialDialog by remember { mutableStateOf(false) }

    LazyColumn(
        modifier = Modifier.fillMaxSize().padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {

        item {
            Button(onClick = { showStudyDialog = true }, modifier = Modifier.fillMaxWidth()) {
                Text("記録する（時間）")
            }
        }

        item {
            OutlinedButton(onClick = { showMaterialDialog = true }, modifier = Modifier.fillMaxWidth()) {
                Text("教材の追加")
            }
        }

        if (vm.materials.isNotEmpty()) {
            item { Text("追加した教材", style = MaterialTheme.typography.titleMedium) }
            items(vm.materials.size) { i ->
                val m = vm.materials[i]
                Card {
                    Column(Modifier.padding(12.dp)) {
                        Text(m.title, style = MaterialTheme.typography.titleSmall)
                        Text(m.finishedAt.toString(), style = MaterialTheme.typography.labelSmall)
                        if (m.comment.isNotBlank()) Text(m.comment, style = MaterialTheme.typography.bodySmall)
                    }
                }
            }
        }
    }

    if (showStudyDialog) {
        StudyRecordDialog(
            onDismiss = { showStudyDialog = false },
            onSave = { minutes, date ->
                vm.addRecord(date, minutes)
                showStudyDialog = false
            }
        )
    }

    if (showMaterialDialog) {
        MaterialDialog(
            onDismiss = { showMaterialDialog = false },
            onSave = { title, date, comment ->
                vm.addMaterial(title, date, comment)
                showMaterialDialog = false
            }
        )
    }
}

@Composable private fun StudyRecordDialog(onDismiss: () -> Unit, onSave: (Int, LocalDate) -> Unit) {
    var minutesText by remember { mutableStateOf("") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("学習時間を追加") },
        text = {
            OutlinedTextField(
                value = minutesText,
                onValueChange = { minutesText = it.filter(Char::isDigit) },
                label = { Text("分") }
            )
        },
        confirmButton = {
            TextButton(onClick = {
                val min = minutesText.toIntOrNull() ?: 0
                onSave(min, LocalDate.now())
            }) { Text("保存") }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("キャンセル") }
        }
    )
}

@Composable private fun MaterialDialog(onDismiss: () -> Unit, onSave: (String, LocalDate, String) -> Unit) {
    var title by remember { mutableStateOf("") }
    var comment by remember { mutableStateOf("") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("教材の追加") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(title, { title = it }, label = { Text("教材名") })
                OutlinedTextField(comment, { comment = it }, label = { Text("メモ") })
            }
        },
        confirmButton = {
            TextButton(onClick = {
                onSave(title, LocalDate.now(), comment)
            }) { Text("保存") }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("キャンセル") }
        }
    )
}
