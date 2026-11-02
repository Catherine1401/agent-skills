import json


class Question:
    def __init__(self, num, text, options, correct, explanation):
        self.num = num
        self.text = text
        self.options = options
        self.correct = correct
        self.explanation = explanation

    # Kiểu câu theo số đáp án đúng
    def q_type(self):
        return "Checkbox" if len(self.correct) > 1 else "Multiple Choice"

    # Đáp án đúng lên trước theo thứ tự nguồn, phương án sai giữ thứ tự gốc
    def ordered(self):
        wrong = [o for i, o in enumerate(self.options) if i not in self.correct]
        return [self.options[i] for i in sorted(self.correct)] + wrong

    # Giá trị cột Correct Answer: 1..N
    def answer_cell(self):
        n = len(self.correct)
        return 1 if n == 1 else ",".join(str(i) for i in range(1, n + 1))


# Đọc và kiểm tra file JSON trung gian
def load(path):
    min_opts, max_opts = 2, 5
    with open(path, encoding="utf-8") as f:
        raw = json.load(f)
    questions = [Question(r["num"], r["text"], r["options"], r["correct"],
                          r.get("explanation")) for r in raw]
    for q in questions:
        assert q.text and min_opts <= len(q.options) <= max_opts, q.num
        assert all(o for o in q.options), q.num
        assert q.correct and len(set(q.correct)) == len(q.correct), q.num
        assert all(0 <= i < len(q.options) for i in q.correct), q.num
        assert len(q.correct) < len(q.options), q.num
    nums = [q.num for q in questions]
    assert len(set(nums)) == len(nums), "duplicate num"
    return sorted(questions, key=lambda q: q.num)
