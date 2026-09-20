# Agent Skills

Portable workflows for Linux coding agents. `skills/` is the canonical source;
`adapters/` contains agent-specific rule formats.

## Cài đặt

```sh
git clone https://github.com/Catherine1401/agent-skills.git
cd agent-skills
./install.sh --agent codex
```

Cài cho tất cả agent được hỗ trợ:

```sh
./install.sh --agent all --mode symlink
```

## Tham số `install.sh`

| Tham số | Ý nghĩa |
| --- | --- |
| `--agent codex` | Cài skill và quy tắc cho Codex, vào `~/.codex`. |
| `--agent claude` | Cài cho Claude Code, vào `~/.claude`. |
| `--agent cursor` | Cài cho Cursor, vào `~/.cursor`. |
| `--agent all` | Cài lần lượt cho Codex, Claude Code và Cursor. |
| `--mode symlink` | Mặc định. Tạo liên kết tới repo; sửa repo rồi là các agent dùng bản mới. Không nên xóa hoặc di chuyển repo sau khi cài. |
| `--mode copy` | Sao chép file thay vì liên kết; phù hợp khi muốn cài độc lập. Cần chạy lại lệnh sau mỗi lần cập nhật repo. |
| `--no-rules` | Chỉ cài skill, không thêm quy tắc commit toàn cục. |
| `--force` | Nếu đích đã tồn tại, chuyển bản cũ thành file/thư mục backup có timestamp rồi cài bản mới. |
| `--dry-run` | In các thay đổi dự kiến, không ghi file. Dùng để kiểm tra trước. |
| `--help` hoặc `-h` | Hiện cú pháp lệnh. |

Ví dụ an toàn trước khi cài:

```sh
./install.sh --agent all --dry-run
./install.sh --agent all --force
```

Mặc định có thể đổi thư mục cấu hình bằng biến môi trường `CODEX_HOME`,
`CLAUDE_CONFIG_DIR` hoặc `CURSOR_CONFIG_DIR`:

```sh
CODEX_HOME=/opt/codex ./install.sh --agent codex --mode copy
```

## Kiểm tra

```sh
./tests/test-install.sh
```
