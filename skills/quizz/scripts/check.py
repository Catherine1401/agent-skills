import glob
import os
import sys

import openpyxl

from model import load


# Trả về số câu sai khi so dòng xlsx với câu trong JSON
def check_file(path, by_num, seen):
    data_row = 3
    max_opts = 5
    rows = [r for r in openpyxl.load_workbook(path).active.iter_rows(min_row=data_row, values_only=True) if r[0]]
    bad = []
    for r in rows:
        match = [x for x in by_num.values() if x.text == r[0] and x.num not in seen]
        if not match:
            bad.append(r[0][:40])
            continue
        q = match[0]
        seen.add(q.num)
        expect = q.ordered() + [None] * (max_opts - len(q.options))
        if (list(r[2:7]) != expect or r[1] != q.q_type()
                or str(r[7]) != str(q.answer_cell())):
            bad.append(q.num)
    return len(rows), bad


def main(json_path, out_dir, prefix):
    questions = load(json_path)
    by_num = {q.num: q for q in questions}
    seen = set()
    for path in sorted(glob.glob(os.path.join(out_dir, f"{prefix}_*.xlsx"))):
        count, bad = check_file(path, by_num, seen)
        print(os.path.basename(path), "rows", count, "bad", bad)
    print("coverage complete:", seen == set(by_num))


if __name__ == "__main__":
    main(*sys.argv[1:4])
