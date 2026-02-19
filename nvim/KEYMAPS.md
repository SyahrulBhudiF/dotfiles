# Neovim Keymap Cheat Sheet (Simple & Clear)

**Catatan penting:**  
Di config ini, “Leader” = **tombol Space**.  
Jadi kalau kamu lihat `<Leader>f`, artinya tekan **Space lalu f**.

---

## Navigasi Jendela (pindah antar panel)
- **Ctrl + h** → ke panel kiri  
- **Ctrl + l** → ke panel kanan  
- **Ctrl + j** → ke panel bawah  
- **Ctrl + k** → ke panel atas  

---

## File & Pencarian
- **Ctrl + n** → buka/tutup file tree (Neo-tree)  
- **Space + f** → cari file (file picker)  
- **Space + /** → cari teks di semua file (grep)  
- **Space + n** → hilangkan highlight hasil search  

---

## Neo-tree (File Tree) Saat Fokus
- **l** → buka folder / file  
- **h** → tutup folder  
- **Y** → copy full path file  
- **O** → buka file dengan aplikasi sistem  
- **P** → toggle preview  

---

## LSP (Fitur pintar bahasa)
- **Space + k** → lihat dokumentasi simbol  
- **Space + a** → code action (quick fix, refactor)  
- **g d** → lompat ke definisi  
- **Space + r** → rename simbol  
- **Space + gr** → list referensi  
- **Space + l** → jalankan CodeLens  
- **Space + d** → lihat diagnostic di baris  
- **] d** → diagnostic berikutnya  
- **[ d** → diagnostic sebelumnya  
- **Ctrl + s** (di insert) → signature help  

---

## Git (Gitsigns)
**Penjelasan singkat:**  
`gs` = group git signs  
`gsl` = git signs blame line  
`gsp` = git signs preview hunk  

- **Space + g s l** → blame 1 baris (lihat siapa edit)  
- **Space + g s b** → blame seluruh buffer  
- **Space + g s d** → diff file sekarang  
- **Space + g s s** → stage hunk  
- **Space + g s p** → preview hunk  
- **Space + g s r** → reset hunk  
- **Space + g s R** → reset semua hunk di file  

**Navigasi hunk:**
- **] h** → hunk berikutnya  
- **[ h** → hunk sebelumnya  
- **] H** → hunk terakhir  
- **[ H** → hunk pertama  

---

## Buffers & Tools (Snacks)
- **Space + b d** → hapus buffer  
- **Ctrl + /** → toggle terminal  
- **Space + z** → toggle Zen mode  
- **Space + u n** → tutup semua notifikasi  
- **Space + c R** → rename file  
- **Space + g g** → buka lazygit  
- **Ketik `:FormatToggle`** → nyalakan/matikan format otomatis saat save  

---

## Visual Mode
- **<** → indent kiri  
- **>** → indent kanan  
- **Alt + y** → copy ke clipboard sistem  

---

## Kecil tapi penting
- **Q** → disable Ex mode  
- **q:** → disable command-line history window  

---

## Tips Cepat
- Tekan **Space + ?** untuk lihat keymap lokal di buffer  
- Tekan **Space + g s** untuk lihat grup keymap Git