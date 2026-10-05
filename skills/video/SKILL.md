---
name: video
description: Read a video file (.mp4/.mov/.webm) by extracting frames with ffmpeg and summarizing what it shows, e.g. a QA bug recording. Use when given a video path; not for still images or live app testing.
context: fork
---

- Require `ffmpeg`; if missing, report it and stop. Install only with user approval, preferring a no-sudo static build.
- Work in a temp dir (`$CLAUDE_JOB_DIR/tmp` when set, else `mktemp -d`); never write beside the video.
- Get the duration with `ffprobe`. Extract frames at 1 fps with `-vf "fps=1,scale='min(1280,iw)':-2"` (never upscale); use `-ss`/`-t` when the user gives a time range, and higher fps only for fast transitions.
- Read up to 15 frames directly. For more, delegate to one subagent when available, passing the frame dir, the user's bug description, the video duration, and the frame-to-second rule below with an instruction to report each moment as a second from that rule (never invent times beyond the video duration), and use only its summary; otherwise sample fewer frames.
- Extract and transcribe audio only when the user wants speech and `whisper` is available; otherwise state that audio was not analyzed.
- Report only what frames show, with the second of each observation (second = frame number − 1 at 1 fps, plus any `-ss` offset), and state that motion, timing between frames, and sound are not covered. Do not infer a root cause without code evidence.
