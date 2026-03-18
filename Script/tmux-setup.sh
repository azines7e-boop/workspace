#!/bin/bash
# tmux 세션 자동 생성 스크립트

sessions=("claude" "claude-sub" "clm")

for session in "${sessions[@]}"; do
  if ! tmux has-session -t "$session" 2>/dev/null; then
    tmux new-session -d -s "$session"
    if [ "$session" = "clm" ]; then
      tmux send-keys -t "$session" "export TZ=Asia/Seoul" Enter
    fi
    echo "세션 생성: $session"
  else
    echo "이미 존재: $session"
  fi
done

echo ""
echo "사용법:"
echo "  tmux attach -t claude"
echo "  tmux attach -t claude-sub"
echo "  tmux attach -t clm"
