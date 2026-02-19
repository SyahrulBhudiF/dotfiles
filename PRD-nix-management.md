# PRD — Nix Management for Dotfiles (Non‑Hypr/Caelestia)

## 1) Tujuan
Mengelola sebanyak mungkin dependency dan konfigurasi dotfiles via Nix/Home‑Manager agar setup lebih konsisten, reproducible, dan mudah dipindahkan.

## 2) Scope
**Termasuk:**
- Paket CLI & tooling yang jelas dipakai di config (`zsh`, `starship`, `zoxide`, `neovim`, `fastfetch`, `ghostty`, dll).
- Enable program Home‑Manager yang sesuai.
- Symlink config ke `~/.config` dan dotfiles standar (`~/.zshrc`, `~/.zshenv`, `~/.profile`).

**Dikecualikan:**
- Semua komponen **Hypr** dan **Caelestia** (config, scripts, dependency).

## 3) Non‑Goals
- Tidak melakukan refactor isi config (misalnya merapikan `.zshrc` atau `config.nu`).
- Tidak menghapus alat yang sudah dipakai di luar Nix.
- Tidak mengubah struktur repo atau nama file.

## 4) Requirements
### Functional
- Semua tool yang dipakai di config non‑Hypr harus tersedia via Nix.
- `home-manager` mengelola config untuk:
  - `zsh`, `starship`, `zoxide`
  - `nvim`
  - `nu`
  - `fastfetch`
  - `ghostty`
- Config tetap menunjuk ke file dalam repo (dotfiles sebagai single source of truth).

### Compatibility
- Tetap kompatibel dengan `nixpkgs` & `home-manager` yang ada di `flake.nix`.
- Tidak menambahkan paket yang tidak ada di nixpkgs (hindari overlay custom kalau belum perlu).

## 5) Acceptance Criteria
- `home-manager switch --flake .#ryuko` berjalan tanpa error untuk scope non‑Hypr.
- Tools (`zsh`, `starship`, `zoxide`, `neovim`, `fastfetch`, `ghostty`, `nushell`) tersedia setelah switch.
- Config utama ter‑link dari repo ke lokasi standar di `$HOME`.

### Status (Update)
- ✅ `home-manager switch -b backup --flake .#ryuko` berhasil dijalankan.
- ✅ Paket `zsh`, `starship`, `zoxide`, `neovim`, `fastfetch`, `ghostty` sudah ditambahkan ke `modules/packages.nix`.
- ✅ Home‑Manager sudah mengelola `zsh`, `starship`, `zoxide`.
- ✅ Symlink config non‑Hypr sudah ditambahkan (`zsh`, `nu`, `nvim`, `fastfetch`, `ghostty`, `jjui`, `.profile`).
- ✅ Migrasi `nvm` → `nodejs` via Nix (Node.js latest) sudah dilakukan; inisialisasi NVM dihapus.
- ✅ Path portability: `~`/`/home/ryuko` diganti ke `$HOME` di `zsh`, `.profile`, dan `nu`.

## 6) Assumptions
- Repo ini adalah sumber kebenaran untuk config.
- User ingin reproducibility daripada manual install.

## 7) Risks & Mitigations
- **Risk:** Konflik dengan file config existing di `$HOME`.  
  **Mitigation:** Home‑Manager akan overwrite symlink; user aware.
- **Risk:** Perubahan enable `zsh/starship/zoxide` bisa mengubah behavior login shell.  
  **Mitigation:** Hanya enable program, tidak mengubah isi config.

## 8) Remaining Items / Open Questions
- Perlu tambah paket lain di Nix untuk kebutuhan non‑Hypr (misal `git`, `pass`, dll) atau sudah cukup?
- `jq` masih di-skip karena hanya dipakai di Hypr scripts (sesuai scope). Konfirmasi kalau mau dimasukkan juga.