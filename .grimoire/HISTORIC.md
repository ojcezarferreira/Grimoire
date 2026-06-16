# HISTORIC

1. **006-user-facing-language** [spec] — Normalizes every hardcoded operator-facing string in the plugin source from pt-BR to English (canonical translatable templates) and adds a new `§ User-facing language` convention: source strings are English, but every skill renders terminal communication in the user's native language (detected from session input, OS-locale fallback, English final fallback), preserving literal tokens. Wires the new section into all 11 SKILL.md `[Required Reading]` blocks and ships a version bump + CHANGELOG entry.
