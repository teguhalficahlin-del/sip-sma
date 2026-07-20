# NOVA — Prompt Master Claude Code
## Fase 4B: Ekosistem Belajar Rumah-Sekolah
**Gunakan prompt ini setelah Fase 4 selesai dan dikonfirmasi.**

---

## KONTEKS PROJECT

Kamu melanjutkan pembangunan **NOVA (Next-gen One-stop Virtual Academy)** — platform ekosistem belajar multi-tenant untuk SD-SMP-SMA di Indonesia.

**Fase 4 sudah selesai dan terverifikasi:**
- CP dan ATP sudah bisa di-generate dan disetujui guru
- Modul ajar per minggu sudah bisa dibuat dan dibagikan ke siswa
- Jurnal mengajar, tugas, dan pengumpulan tugas berfungsi

**Fase 4B ini adalah ekstensi dari Fase 4** — membangun jembatan antara pembelajaran di sekolah dan di rumah. Guru membagikan materi ke orang tua, orang tua dan siswa bisa membaca materi dan bertanya ke AI yang berbasis konten guru.

Ini adalah fitur yang membedakan NOVA dari platform manapun — **AI yang menjawab berdasarkan materi yang sudah disusun guru, bukan AI generik.**

Baca `CLAUDE.md` dan `SPEC.md` di root repository sebelum mulai.

---

## ATURAN KERJA WAJIB

1. **Baca dulu, kode kemudian** — analisis seluruh instruksi sebelum mulai
2. **Satu langkah selesai sebelum lanjut**
3. **Tidak ada placeholder** — semua kode harus fungsional
4. **RLS wajib diuji** — setiap tabel baru harus diverifikasi isolasinya
5. **Mobile-first wajib** — semua UI diuji di 320px
6. **Tidak ada keputusan arsitektur mandiri** — jika ambigu, tanyakan dulu
7. **Commit per langkah**
8. **Service Worker tidak disentuh** — SW di Fase 7

---

## PERILAKU AI TUTOR

Ini adalah aturan paling kritis di Fase 4B:

**Tipe 1 — Pertanyaan tentang materi guru:**
AI menjawab HANYA berdasarkan konten modul yang sudah disusun guru untuk kelas tersebut. Tidak mengarang, tidak menambah dari sumber lain.

**Tipe 2 — Pertanyaan pengembangan:**
AI boleh menjawab lebih luas, tapi TETAP dalam konteks topik yang sedang dipelajari. Contoh: jika topik adalah "Pecahan", AI boleh jelaskan cara menghitung pecahan dengan contoh nyata sehari-hari — tapi tidak melompat ke topik aljabar.

**Tipe 3 — Pertanyaan di luar konteks:**
AI menolak dengan ramah dan mengarahkan kembali:
*"Pertanyaan ini di luar materi yang sedang dipelajari. Saya bisa bantu jelaskan [topik materi] jika ada yang belum jelas."*

**System prompt AI tutor:**
```
Kamu adalah asisten belajar yang membantu orang tua dan siswa memahami materi pelajaran.

Materi yang sedang dipelajari:
{lesson_module_content}

Topik: {topic}
Mata Pelajaran: {subject}
Kelas: {grade}

Aturan yang WAJIB kamu ikuti:
1. Untuk pertanyaan tentang materi: jawab HANYA berdasarkan konten materi di atas
2. Untuk pertanyaan pengembangan: jawab dalam konteks topik {topic}, tidak boleh melompat ke topik lain
3. Untuk pertanyaan di luar konteks: tolak dengan ramah dan arahkan ke topik {topic}
4. Gunakan bahasa Indonesia yang sederhana — pengguna adalah orang tua dan siswa SD-SMP-SMA
5. Berikan contoh nyata dari kehidupan sehari-hari jika membantu pemahaman
6. JANGAN menggunakan istilah teknis tanpa penjelasan
7. Jawaban maksimal 3 paragraf pendek — tidak perlu panjang
```

---

## FASE 4B — EKOSISTEM BELAJAR RUMAH-SEKOLAH

### Target Fase 4B
- Guru bisa memilih materi modul ajar mana yang dibagikan ke orang tua
- Orang tua bisa membaca materi yang dibagikan guru di HP mereka
- Orang tua bisa bertanya ke AI tentang materi — AI menjawab berdasarkan konten guru
- Siswa bisa melakukan hal yang sama
- Log percakapan tersimpan per modul per pengguna

---

### Langkah-langkah

#### LANGKAH 1 — Update Tabel `lesson_modules`
Tambahkan field baru ke tabel `lesson_modules` yang sudah ada:

```sql
ALTER TABLE lesson_modules ADD COLUMN IF NOT EXISTS
  is_shared_to_parent boolean default false;

ALTER TABLE lesson_modules ADD COLUMN IF NOT EXISTS
  shared_at timestamptz;

ALTER TABLE lesson_modules ADD COLUMN IF NOT EXISTS
  shared_by uuid references users(id);
```

**Logika sharing:**
- Guru tap toggle "Bagikan ke Orang Tua & Siswa" di halaman modul
- `is_shared_to_parent` berubah menjadi `true`
- Timestamp dan ID guru yang membagikan tercatat
- Orang tua & siswa kelas tersebut langsung bisa akses

**Update RLS `lesson_modules`:**
- Tambahkan policy: orang tua bisa baca modul jika `is_shared_to_parent = true` DAN anaknya ada di kelas modul tersebut
- Siswa bisa baca modul jika `is_shared_to_parent = true` DAN dia ada di kelas tersebut

**Update UI guru:**
- Tambahkan toggle "Bagikan ke Rumah" di `src/pages/teacher/GenerateModule.jsx` — Langkah 8
- Tampilkan status: "Sudah dibagikan" / "Belum dibagikan"
- Guru bisa cabut sharing kapan saja

**Verifikasi:**
- Modul yang belum dibagikan tidak terlihat orang tua & siswa
- Modul yang sudah dibagikan langsung terlihat di dashboard orang tua & siswa
- Guru bisa toggle on/off kapan saja

---

#### LANGKAH 2 — Tabel `ai_conversations`
Buat migration file untuk tabel `ai_conversations`:

```sql
id uuid primary key default gen_random_uuid()
school_id uuid references schools(id) not null
lesson_module_id uuid references lesson_modules(id) not null
user_id uuid references users(id) not null -- ortu atau siswa
role text not null -- 'parent' | 'student'
messages jsonb not null -- array [{role: 'user'|'assistant', content: '...'}]
question_count integer default 0
created_at timestamptz default now()
updated_at timestamptz default now()
UNIQUE(lesson_module_id, user_id) -- satu percakapan per modul per pengguna
```

**RLS:**
- Pengguna hanya bisa lihat percakapannya sendiri
- Guru bisa lihat semua percakapan di modulnya (untuk evaluasi pemahaman)
- Admin bisa lihat semua percakapan di sekolahnya

**Rate limiting AI tutor:**
- Maksimal 20 pertanyaan per pengguna per hari (lebih longgar dari generate modul)
- Tersimpan di tabel `rate_limits` yang sudah ada — tambahkan type `'ai_tutor'`

---

#### LANGKAH 3 — UI Orang Tua: Halaman Materi

**Buat `src/pages/parent/LearningMaterials.jsx`:**

**Tampilan daftar materi yang dibagikan:**
- List modul yang sudah dibagikan guru untuk kelas anak
- Sorted: terbaru di atas
- Setiap kartu menampilkan: nama mapel, topik, minggu ke berapa, nama guru
- Badge "Baru" jika belum pernah dibuka

**Tampilan detail materi + AI tutor (`src/pages/parent/MaterialDetail.jsx`):**

Halaman ini dibagi dua section:

**Section atas — Materi:**
- Judul topik
- Konten modul ajar dalam format yang mudah dibaca orang tua
  - Tujuan pembelajaran (dalam bahasa sederhana)
  - Materi pokok
  - Contoh-contoh
  - Aktivitas yang bisa dilakukan di rumah

**Section bawah — Tanya AI:**
- Header: *"Ada yang belum jelas? Tanya di sini"*
- Tampilan percakapan seperti chat (bubble message)
- Field input teks + tombol kirim
- Indikator loading saat AI sedang menjawab
- Pesan sambutan awal: *"Halo! Saya siap membantu Anda memahami materi [topik]. Silakan tanya apa saja tentang materi ini."*

**Desain khusus untuk orang tua:**
- Font size lebih besar dari default (minimal 16px)
- Bahasa sangat sederhana di semua label dan placeholder
- Tombol besar dan mudah di-tap
- Tidak ada istilah teknis di UI

---

#### LANGKAH 4 — UI Siswa: Halaman Materi

**Buat `src/pages/student/LearningMaterials.jsx`:**

Mirip dengan halaman orang tua, tapi dengan penyesuaian:
- Bahasa lebih sesuai untuk siswa (bukan "Bapak/Ibu" tapi "Kamu")
- Tambahkan section "Rangkuman Singkat" di atas materi lengkap — cocok untuk siswa yang butuh overview cepat
- AI tutor menggunakan bahasa yang lebih santai dan encouraging

**Buat `src/pages/student/MaterialDetail.jsx`:**
- Struktur sama dengan parent, tapi tone AI lebih santai
- Contoh pesan sambutan: *"Hai! Ada yang mau kamu tanyakan soal [topik]? Yuk kita bahas bareng!"*

---

#### LANGKAH 5 — Integrasi Claude API untuk AI Tutor

**Tambahkan fungsi baru di `src/lib/claude.js`:**

```javascript
async function askAITutor({
  lessonModuleContent,
  topic,
  subject,
  grade,
  conversationHistory,
  userQuestion,
  userId,
  moduleId,
  userRole // 'parent' | 'student'
}) {
  // 1. Cek rate limit (20 pertanyaan/hari)
  const todayCount = await checkDailyLimit(userId, 'ai_tutor');
  if (todayCount >= 20) {
    throw new Error('Batas pertanyaan harian tercapai (20x per hari). Coba lagi besok.');
  }

  // 2. Klasifikasi pertanyaan
  const questionType = await classifyQuestion(userQuestion, topic);
  // 'on_topic' | 'extension' | 'off_topic'

  if (questionType === 'off_topic') {
    return {
      answer: `Pertanyaan ini di luar materi yang sedang dipelajari. Saya bisa bantu jelaskan tentang "${topic}" jika ada yang belum jelas.`,
      questionType: 'off_topic'
    };
  }

  // 3. Sanitasi input
  const sanitizedQuestion = sanitizeInput(userQuestion);

  // 4. Build messages dengan conversation history
  const messages = [
    ...conversationHistory,
    { role: 'user', content: sanitizedQuestion }
  ];

  // 5. Tone berbeda untuk parent vs student
  const toneInstruction = userRole === 'parent'
    ? 'Gunakan bahasa sopan dan formal untuk orang tua.'
    : 'Gunakan bahasa santai dan menyemangati untuk siswa.';

  // 6. Call Claude API
  const systemPrompt = buildAITutorSystemPrompt({
    lessonModuleContent,
    topic,
    subject,
    grade,
    toneInstruction
  });

  const response = await fetch(CLAUDE_API_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      model: MODEL,
      max_tokens: 500, // jawaban pendek, maksimal 3 paragraf
      system: systemPrompt,
      messages
    })
  });

  const data = await response.json();
  const answer = data.content[0].text;

  // 7. Simpan ke ai_conversations & increment counter
  await saveConversation(moduleId, userId, messages, answer);
  await incrementDailyLimit(userId, 'ai_tutor');

  return { answer, questionType };
}
```

---

#### LANGKAH 6 — Notifikasi ke Orang Tua

Saat guru membagikan modul baru, orang tua siswa di kelas tersebut mendapat notifikasi:

```
Judul: "Materi Baru dari [nama guru]"
Isi: "Materi [topik] untuk [mapel] sudah tersedia. Buka NOVA untuk membaca bersama anak."
```

Tambahkan ke sistem notifikasi yang sudah dibangun di Fase 5 — event type baru: `'material_shared'`.

---

#### LANGKAH 7 — Dashboard Guru: Insight Percakapan

Guru bisa melihat insight dari percakapan AI di modulnya — untuk evaluasi seberapa baik materi dipahami.

**Tambahkan section di `src/pages/teacher/GenerateModule.jsx` (halaman detail modul):**

**Insight Pemahaman:**
- Jumlah orang tua yang sudah buka materi ini
- Jumlah pertanyaan yang masuk ke AI tutor
- Topik/kata kunci yang paling sering ditanyakan (aggregated, bukan isi percakapan individual)

Ini membantu guru tahu bagian mana dari materi yang paling membingungkan orang tua dan siswa — dan bisa dijadikan bahan perbaikan modul berikutnya.

---

#### LANGKAH 8 — Update CLAUDE.md

```markdown
## Status Fase
- [x] Fase 1: Foundation
- [x] Fase 2: Core Akademik
- [x] Fase 3: Penilaian
- [x] Fase 4: Pembelajaran (CP, ATP, Modul Ajar, Tugas)
- [x] Fase 4B: Ekosistem Belajar Rumah-Sekolah
- [ ] Fase 5: Komunikasi
- [ ] Fase 6: Laporan & Dashboard
- [ ] Fase 7: Hardening

## Keputusan Arsitektur yang Sudah Fix
- [2026-07-07] Multi-tenant: school_id + RLS
- [2026-07-07] Stack: Hybrid cloud (Supabase → VPS)
- [2026-07-07] Auth ortu: WhatsApp OTP
- [2026-07-07] Auth siswa: NIS + password
- [2026-07-07] Service Worker: diaktifkan di Fase 7
- [2026-07-07] Absensi: tidak bisa duplikasi per kelas + mapel + tanggal
- [2026-07-07] Rapor: TIDAK masuk platform
- [2026-07-07] Tipe penilaian: harian | tengah_semester | observasi_perilaku
- [2026-07-07] Claude API generate modul: rate limit 10x/hari, cache aktif
- [2026-07-07] CP: AI generate, guru review & approve sebelum generate ATP
- [2026-07-07] ATP: AI generate dari CP, breakdown 18 minggu per semester
- [2026-07-07] AI tutor: menjawab berdasarkan konten guru; pertanyaan pengembangan dalam konteks topik; pertanyaan di luar konteks ditolak ramah
- [2026-07-07] AI tutor rate limit: 20 pertanyaan per pengguna per hari
- [2026-07-07] Sharing materi: guru kontrol via toggle, orang tua & siswa hanya lihat yang dibagikan
- [2026-07-07] Tone AI tutor: formal untuk orang tua, santai untuk siswa
```

---

## CHECKLIST SELESAI FASE 4B

- [ ] Field `is_shared_to_parent` ditambah ke `lesson_modules`
- [ ] Toggle "Bagikan ke Rumah" berfungsi di halaman guru
- [ ] RLS update — ortu & siswa hanya lihat modul yang dibagikan
- [ ] Tabel `ai_conversations` terbuat + RLS aktif
- [ ] Rate limit AI tutor: 20 pertanyaan/hari berfungsi
- [ ] Halaman materi orang tua berfungsi — list + detail + AI chat
- [ ] Halaman materi siswa berfungsi — list + detail + AI chat
- [ ] AI tutor menjawab berdasarkan konten guru (bukan generik)
- [ ] AI tutor menolak pertanyaan di luar konteks dengan ramah
- [ ] Tone AI berbeda: formal untuk ortu, santai untuk siswa
- [ ] Notifikasi ke orang tua saat materi baru dibagikan
- [ ] Dashboard guru menampilkan insight percakapan
- [ ] `CLAUDE.md` diupdate dengan status Fase 4B selesai
- [ ] Semua langkah sudah di-commit ke GitHub

---

## SETELAH FASE 4B SELESAI

Laporkan:
1. Checklist di atas — centang semua yang sudah selesai
2. Demo alur: guru bagikan materi → orang tua terima notifikasi → buka materi → tanya AI → AI jawab berdasarkan konten guru
3. Konfirmasi AI menolak pertanyaan di luar konteks dengan benar
4. Jika ada item yang tidak bisa diselesaikan — jelaskan kenapa dan tunggu instruksi

**Jangan mulai Fase 5 sebelum mendapat konfirmasi.**
