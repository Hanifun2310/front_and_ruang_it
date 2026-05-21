import 'package:get/get.dart';

class GuidelinesController extends GetxController {
  var isLoading = false.obs;
  var htmlContent = r'''
<div style="color: inherit;">
  <h2 style="color: #092BA2; font-size: 20px; font-weight: bold; margin-bottom: 16px;">Syarat & Ketentuan</h2>
  
  <h3 style="font-size: 17px; font-weight: bold; margin-top: 24px; margin-bottom: 12px;">Standar Penulisan Artikel</h3>
  
  <p><strong>1. Struktur Artikel</strong></p>
  <ul>
    <li><strong>Judul:</strong> Singkat, jelas, dan sesuai topik. Contoh: “Mengenal Cloud Computing untuk Pemula”</li>
    <li><strong>Pendahuluan:</strong> Jelaskan topik secara sederhana dan kenapa penting bagi pembaca.</li>
    <li><strong>Isi Artikel:</strong>
      <ul>
        <li>Gunakan paragraf pendek.</li>
        <li>Jelaskan konsep secara jelas dan mudah dipahami.</li>
        <li>Sertakan contoh nyata atau analogi sederhana.</li>
      </ul>
    </li>
    <li><strong>Kesimpulan:</strong> Ringkas poin penting dari artikel. Bisa tambahkan ajakan membaca artikel lain atau praktik sederhana.</li>
  </ul>

  <p><strong>2. Gaya Bahasa</strong></p>
  <ul>
    <li>Gunakan bahasa Indonesia yang mudah dimengerti.</li>
    <li>Hindari istilah teknis yang sulit; jika perlu, beri definisi singkat.</li>
    <li>Tulisan harus ramah untuk pembaca pemula.</li>
  </ul>

  <p><strong>3. Sumber dan Akurasi</strong></p>
  <ul>
    <li>Gunakan informasi dari sumber terpercaya.</li>
    <li>Cantumkan referensi jika mengutip fakta atau data.</li>
    <li>Pastikan konten tidak menyesatkan atau salah kaprah.</li>
  </ul>

  <p><strong>4. Etika</strong></p>
  <ul>
    <li>Tidak boleh menyalin konten orang lain tanpa izin.</li>
    <li>Fokus pada edukasi, bukan opini pribadi atau promosi.</li>
    <li>Pastikan artikel aman dan sesuai untuk semua pembaca.</li>
  </ul>

  <h3 style="font-size: 17px; font-weight: bold; margin-top: 32px; margin-bottom: 12px;">Ketentuan Pemblokiran</h3>

  <p><strong>1. Blokir Pengguna</strong></p>
  <p><strong>Alasan Pemblokiran:</strong></p>
  <ul>
    <li>Melanggar aturan penulisan (plagiarisme, spam, konten menyesatkan).</li>
    <li>Mengunggah konten yang mengandung kekerasan, SARA, atau materi ilegal.</li>
    <li>Menggunakan bahasa kasar atau menyerang pengguna lain.</li>
  </ul>
  <p><strong>Prosedur:</strong></p>
  <ul>
    <li>Pengguna yang terblokir tidak bisa login ke akunnya sampai admin mencabut status blokirnya.</li>
    <li>Pengguna yang terblokir silahkan menghubungi admin untuk membicarakan status blokirnya.</li>
  </ul>

  <p><strong>2. Blokir Artikel</strong></p>
  <p><strong>Alasan Pemblokiran:</strong></p>
  <ul>
    <li>Mengandung informasi palsu atau menyesatkan.</li>
    <li>Melanggar hak cipta.</li>
    <li>Mengandung konten SARA, kekerasan, atau materi ilegal.</li>
  </ul>
  <p><strong>Prosedur:</strong></p>
  <ul>
    <li>Artikel akan disembunyikan dari publik.</li>
    <li>Jika pelanggaran berulang, penulis dapat diblokir sementara atau permanen.</li>
    <li>Pengguna yang artikelnya terblokir silahkan menghubungi admin untuk membicarakan status blokirnya.</li>
  </ul>

  <p><strong>3. Blokir Komentar</strong></p>
  <p><strong>Alasan Pemblokiran:</strong></p>
  <ul>
    <li>Komentar spam atau promosi.</li>
    <li>Mengandung kata-kata kasar, menyerang pribadi, atau diskriminatif.</li>
    <li>Menyebarkan informasi salah atau hoaks.</li>
  </ul>
  <p><strong>Prosedur:</strong></p>
  <ul>
    <li>Komentar akan disembunyikan.</li>
    <li>Pengguna yang melanggar dapat diberikan peringatan.</li>
    <li>Pelanggaran berulang dapat menyebabkan akun diblokir sementara atau permanen dari memberi komentar.</li>
    <li>Pengguna yang terblokir silahkan menghubungi admin untuk membicarakan status blokirnya.</li>
  </ul>
</div>
'''.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
  }

  void loadGuidelines() {
    // Tidak perlu memuat dari API lagi karena sudah statis
  }
}
