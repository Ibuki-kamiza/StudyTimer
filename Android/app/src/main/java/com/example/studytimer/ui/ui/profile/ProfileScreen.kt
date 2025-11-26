package com.example.studytimer.ui.profile

import android.graphics.Bitmap
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts.PickVisualMedia
import androidx.activity.result.contract.ActivityResultContracts.PickVisualMedia.ImageOnly
import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.*
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.unit.dp
import com.example.studytimer.StudyViewModel
import java.time.LocalDate

@Composable
fun ProfileScreen(vm: StudyViewModel) {

    var editing by remember { mutableStateOf(false) }

    Column(Modifier.fillMaxSize().padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {

        Row(verticalAlignment = Alignment.CenterVertically) {
            if (vm.profileImageBitmap != null) {
                Image(
                    bitmap = vm.profileImageBitmap!!.asImageBitmap(),
                    contentDescription = null,
                    modifier = Modifier.size(64.dp)
                )
            }
            Spacer(Modifier.width(12.dp))
            Text(
                vm.profileName,
                style = MaterialTheme.typography.titleLarge,
                modifier = Modifier.clickable { editing = true }
            )
        }

        Text("志望校：${vm.targetSchool}")
        Text("資格：${vm.targetQualifications}")
        Text("大事な日：${vm.importantTitle} (${vm.importantDate})")
    }

    if (editing) {
        ProfileEditDialog(vm, onDismiss = { editing = false })
    }
}

@Composable
private fun ProfileEditDialog(vm: StudyViewModel, onDismiss: () -> Unit) {

    var name by remember { mutableStateOf(vm.profileName) }
    var school by remember { mutableStateOf(vm.targetSchool) }
    var qualifications by remember { mutableStateOf(vm.targetQualifications) }

    var dailyHour by remember { mutableStateOf((vm.dailyGoalMinutes/60).toString()) }
    var dailyMin by remember { mutableStateOf((vm.dailyGoalMinutes%60).toString()) }

    var importantTitle by remember { mutableStateOf(vm.importantTitle) }
    var importantDateText by remember { mutableStateOf(vm.importantDate.toString()) }

    var pickedImage by remember { mutableStateOf<Bitmap?>(vm.profileImageBitmap) }

    val picker = rememberLauncherForActivityResult(PickVisualMedia()) { uri ->
        if (uri != null) {
            val source = android.graphics.ImageDecoder.createSource(LocalContext.current.contentResolver, uri)
            pickedImage = android.graphics.ImageDecoder.decodeBitmap(source)
        }
    }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("プロフィール編集") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(name, { name = it }, label = { Text("名前") })
                OutlinedTextField(school, { school = it }, label = { Text("志望校") })
                OutlinedTextField(qualifications, { qualifications = it }, label = { Text("資格") })

                Row {
                    OutlinedTextField(dailyHour, { dailyHour = it.filter(Char::isDigit) }, label = { Text("時間") }, modifier = Modifier.width(90.dp))
                    Spacer(Modifier.width(8.dp))
                    OutlinedTextField(dailyMin, { dailyMin = it.filter(Char::isDigit) }, label = { Text("分") }, modifier = Modifier.width(90.dp))
                }

                Divider()

                OutlinedTextField(importantTitle, { importantTitle = it }, label = { Text("大事な日のタイトル") })
                OutlinedTextField(importantDateText, { importantDateText = it }, label = { Text("日付 yyyy-MM-dd") })

                Button(onClick = { picker.launch(PickVisualMediaRequest(ImageOnly)) }) {
                    Text("画像を選ぶ")
                }
            }
        },
        confirmButton = {
            TextButton(onClick = {
                val h = dailyHour.toIntOrNull() ?: 0
                val m = dailyMin.toIntOrNull() ?: 0
                val dailyMinutes = h*60 + m

                val importantDate = runCatching { LocalDate.parse(importantDateText) }
                    .getOrElse { vm.importantDate }

                vm.updateProfile(
                    name = name,
                    school = school,
                    qualifications = qualifications,
                    dailyGoalMinutes = dailyMinutes,
                    importantTitle = importantTitle,
                    importantDate = importantDate,
                    image = pickedImage
                )
                vm.scheduleGoalNotifications()
                onDismiss()
            }) { Text("保存") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("キャンセル") } }
    )
}
