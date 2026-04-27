import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profil Saya"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar Section
            Obx(() => CircleAvatar(
              radius: 50,
              backgroundImage: controller.photoProfile.value.isNotEmpty
                  ? NetworkImage('https://ruang-it.vibedev.my.id/storage/${controller.photoProfile.value}')
                  : const NetworkImage('https://ui-avatars.com/api/?name=User'),
            )),
            const SizedBox(height: 24),
            
            // Field Email (Read Only - Sesuai Logika Laravel)
            Obx(() => ListTile(
              title: const Text("Email"),
              subtitle: Text(controller.email.value),
              leading: const Icon(Icons.email_outlined),
            )),
            const Divider(),

            // Form Edit
            TextField(
              controller: controller.nameController,
              decoration: const InputDecoration(labelText: "Nama Lengkap", prefixIcon: Icon(Icons.person_outline)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.professionController,
              decoration: const InputDecoration(labelText: "Pekerjaan", prefixIcon: Icon(Icons.work_outline)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.bioController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Bio Singkat", prefixIcon: Icon(Icons.info_outline), border: OutlineInputBorder()),
            ),
            const SizedBox(height: 32),

            Obx(() => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.isLoading.value ? null : controller.updateProfile,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                child: controller.isLoading.value 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("Simpan Perubahan", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )),
          ],
        ),
      ),
    );
  }
}