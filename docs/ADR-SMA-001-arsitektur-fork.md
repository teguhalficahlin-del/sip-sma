# ADR-SMA-001: Arsitektur SIP SMA — Fork dari SIP SMK

**Tanggal:** 20 Juli 2026  
**Status:** ACCEPTED  
**Decider:** Romo (Teguh Riyono)

---

## Konteks

SIP (Student Insight Platform) saat ini dibangun untuk SMK.
Dibutuhkan versi untuk SMA dengan timeline go-live < 3 bulan.
Mapping gap analysis sudah dilakukan (`docs/mapping-sip-sma-vs-smk.md`).

---

## Keputusan

### 1. Strategi: Fork (Opsi A)

Buat repo baru `student-insight-platform-sma` sebagai fork dari repo SMK.
Bukan multi-tenant, bukan monorepo.

**Alasan:**
- Timeline 3 bulan tidak memungkinkan refactor multi-tenant
- 14 dari 52 fitur (27%) adalah SMK-ONLY — volume yang cukup besar untuk justifikasi repo terpisah
- Risiko regresi ke SIP SMK yang sudah live = nol

### 2. Guard: field `school_type` di tabel `schools`

Tambahkan kolom `school_type` (enum: `'SMK'`, `'SMA'`, `'SMP'`, `'SD'`) ke tabel `schools` sejak awal — di **kedua repo**.  
Tujuan: jaga opsi migrasi ke multi-tenant di masa depan tanpa retrofit besar.

### 3. Fitur yang DIHAPUS dari SIP SMA (SMK-ONLY)

| Item | Keterangan |
|---|---|
| Portal DUDI (seluruh portal) | `dudi/dashboard.html`, `dudi/index.html` |
| PKL / absensi PKL | Tab PKL di portal siswa dan orang tua |
| Program Keahlian / Kaprodi | Tab kaprodi di portal guru, panel "Program Keahlian" di admin |
| Tab WAKA_HUMAS untuk PKL | Tab waka_humas di portal guru |
| Edge function: `bulk-import-dudi` | Backend import mitra DUDI |
| Edge function: `bulk-import-pkl` | Backend import penempatan PKL |
| Edge function: `bulk-import-programs` | Backend import program keahlian |
| Tabel: `vocational_fields` | Schema `core.*` |
| Tabel: `vocational_programs` | Schema `core.*` |
| Tabel: `vocational_concentrations` | Schema `core.*` |
| Tabel: `pkl_placements` | Schema `public` |
| Tabel: `pkl_attendance` | Schema `public` |

### 4. Fitur yang DITAMBAH di SIP SMA (SMA-spesifik)

| Fitur | Fase |
|---|---|
| Modul Nilai / Raport | Fase 1 |
| SNBP/SNBT Tracking | Fase 2 |
| Peminatan siswa | Fase 2 — desain TBD |
| P5 tracking per kelas | Fase 2 |

### 5. Fitur UNIVERSAL dipertahankan tanpa perubahan

Semua 28 fitur universal dari mapping gap analysis (`docs/mapping-sip-sma-vs-smk.md §2`) dipertahankan identik.

---

## Konsekuensi

- Bug fix yang relevan untuk keduanya harus di-apply dua kali (SMK dan SMA)
- Infrastruktur Supabase terpisah (project baru untuk SMA)
- Jika di masa depan ada yayasan SMA+SMK, migrasi ke multi-tenant dimungkinkan via field `school_type` yang sudah ada di kedua repo

---

## Yang Belum Diputuskan (defer ke Phase 2)

- Model database untuk peminatan siswa SMA (tabel `student_specializations` vs flag di `students`)
- Enum role: apakah `WAKA_HUMAS` dipertahankan di SMA untuk fungsi humas umum atau dihapus total
- Scope modul nilai/raport Fase 1: input nilai per KD, per TP, atau hanya nilai akhir per mapel?
