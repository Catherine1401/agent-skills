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

## Đồng bộ giữa các máy

Dùng `symlink` để skill trong thư mục clone luôn phản ánh bản repo hiện tại.
Mỗi máy cần cấu hình Git identity và đăng nhập GitHub với quyền ghi trước khi
agent có thể push:

```sh
git config --global user.name "Tên của bạn"
git config --global user.email "you@example.com"
gh auth login
```

Sau khi một máy đã commit, push thay đổi và bạn muốn nhận bản mới ở máy khác:

```sh
cd agent-skills
./sync.sh --agent all
```

`sync.sh` chỉ fast-forward từ `origin/main`, sau đó cập nhật các rule có marker
do installer quản lý. Nó dừng nếu repo có thay đổi local hoặc lịch sử bị phân
nhánh; commit/push hoặc giải quyết khác biệt trước khi chạy lại. Skill `commit`
vẫn yêu cầu duyệt trước mỗi commit và chỉ push khi bạn yêu cầu.

Các rule được cài cho mọi agent: trả lời bằng tiếng Việt; cập nhật skill với
text tối thiểu, ưu tiên quyết định thực thi của agent; và commit có phạm vi hẹp.

## Thêm skill mới

Tạo `skills/<tên>/SKILL.md`, rồi khai báo nó trong `manifest.yaml`. Installer
cài mọi skill trong section `skills` cho Codex, Claude Code và Cursor:

```yaml
skills:
  commit:
    source: skills/commit
  release:
    source: skills/release
```

Tên entry phải là lowercase/kebab-case, trùng tên thư mục source, và source phải
có `SKILL.md`. Chạy `./tests/test-install.sh` trước khi commit. Máy khác sẽ cài
skill mới ở lần chạy `./sync.sh --agent all` kế tiếp.

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

`sync.sh` nhận `--agent codex|claude|cursor|all` (mặc định `all`), `--dry-run`
và `--help`.

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
