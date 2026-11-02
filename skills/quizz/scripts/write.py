import os
import shutil
import sys

import openpyxl

from model import load


# Ghi một nhóm câu vào bản sao template từ dòng 3
def write_batch(template, out_path, questions):
    data_row = 3
    time_sec = 30
    max_opts = 5
    shutil.copy(template, out_path)
    wb = openpyxl.load_workbook(out_path)
    ws = wb.active
    ws.delete_rows(data_row, ws.max_row)
    for i, q in enumerate(questions):
        opts = q.ordered() + [None] * (max_opts - len(q.options))
        row = [q.text, q.q_type(), *opts, q.answer_cell(), time_sec, None, q.explanation]
        for col, val in enumerate(row, start=1):
            ws.cell(row=data_row + i, column=col, value=val)
    wb.save(out_path)


def main(json_path, out_dir, prefix, template=None):
    batch_size = 50
    # Mặc định dùng template đi kèm skill trong assets/
    template = template or os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "template.xlsx")
    questions = load(json_path)
    os.makedirs(out_dir, exist_ok=True)
    for start in range(0, len(questions), batch_size):
        batch = questions[start:start + batch_size]
        name = f"{prefix}_{batch[0].num:03d}-{batch[-1].num:03d}.xlsx"
        write_batch(template, os.path.join(out_dir, name), batch)
        print(name, len(batch))


if __name__ == "__main__":
    main(*sys.argv[1:])
