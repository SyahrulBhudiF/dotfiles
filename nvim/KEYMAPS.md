# Neovim Keymap Cheat Sheet

**Space = Leader.**  
Contoh: `Space + f` berarti tekan **Spasi** lalu **f**.

---

## Navigasi Jendela
- **Ctrl + h** → ke panel kiri  
- **Ctrl + l** → ke panel kanan  
- **Ctrl + j** → ke panel bawah  
- **Ctrl + k** → ke panel atas  

---

## File & Pencarian
- **Ctrl + n** → buka/tutup file tree (Neo-tree)  
- **Space + f** → cari file  
- **Space + /** → cari teks di semua file  
- **Space + n** → hilangkan highlight search  

---

## Neo-tree (saat fokus di file tree)
- **l** → buka folder / file  
- **h** → tutup folder  
- **Y** → copy full path  
- **O** → buka dengan aplikasi sistem  
- **P** → toggle preview  

---

## LSP (Fitur Bahasa)
- **Space + k** → hover docs  
- **Space + a** → code action  
- **g d** → go to definition  
- **Space + r** → rename symbol  
- **Space + g r** → list references  
- **Space + l** → run CodeLens  
- **Space + d** → diagnostics baris  
- **] d** → diagnostics berikutnya  
- **[ d** → diagnostics sebelumnya  
- **Ctrl + s** (mode insert) → signature help  

---

## Git (Gitsigns)
**Arti singkat:**  
`gs` = group GitSigns  
`gsl` = GitSigns blame line  
`gsp` = GitSigns preview hunk  

- **Space + g s l** → blame 1 baris  
- **Space + g s b** → blame seluruh buffer  
- **Space + g s d** → diff file  
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
- **Space + u n** → tutup notifikasi  
- **Space + c R** → rename file  
- **Space + g g** → buka lazygit  
- **:FormatToggle** → on/off format saat save  

---

## Visual Mode
- **<** → indent kiri  
- **>** → indent kanan  
- **Alt + y** → copy ke clipboard sistem  

---

## Lainnya
- **Q** → nonaktifkan Ex mode  
- **q:** → nonaktifkan command-line history window  

---

## Tips
- **Space + ?** → lihat keymap lokal buffer  
- **Space + g s** → tampilkan grup keymap Git