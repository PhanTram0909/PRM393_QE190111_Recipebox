import docx
from docx.shared import Pt, Inches, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH

def create_report(student_code="QE190111", full_name="Nguyen Van A"):
    doc = docx.Document()

    # Title / Metadata Header
    p_meta = doc.add_paragraph()
    
    metadata = [
        ("Student Code: ", student_code),
        ("Full Name: ", full_name),
        ("GitHub Repository URL: ", "https://github.com/PhanTram0909/PRM393_QE190111_Recipebox"),
        ("APK Download Link: ", f"https://github.com/username/recipe-box/releases/download/v1.0/app-release.apk"),
        ("Firebase Project ID: ", "recipebox-193fc"),
        ("Test account email: ", f"grader.{student_code.lower()}@example.com"),
        ("Test account password: ", "Test1234!"),
    ]

    for label, val in metadata:
        run_label = p_meta.add_run(label)
        run_label.bold = True
        run_label.font.size = Pt(11)
        run_val = p_meta.add_run(val + "\n")
        run_val.font.size = Pt(11)

    doc.add_paragraph().paragraph_format.space_after = Pt(12)

    # Screenshots Heading
    h2 = doc.add_heading("Screenshots", level=1)
    h2.paragraph_format.space_before = Pt(12)
    h2.paragraph_format.space_after = Pt(12)

    screenshots = [
        "Firebase console — Authentication: the Users list showing your test account.",
        "Firebase console — Firestore data: the recipes collection with at least 3 sample documents belonging to your test account.",
        "Firebase console — Security Rules: the Rules tab showing the rules you actually have published, not just saved in an editor.",
        "Register screen — validation: the form submitted empty, showing the error messages.",
        "Register screen — success: right after a successful sign-up, showing Registration successful.",
        "Login screen: the empty sign-in form.",
        "List screen — after login: showing the user’s e-mail, the Logout button, and at least 3 recipes already in the list.",
        "Add Recipe form — validation: the form submitted empty or with bad input, showing the error messages.",
        "Add Recipe form — success: right after adding a recipe, showing Recipe added and the new recipe now in the list.",
        "Filters and search: the category filter, the difficulty filter, the favorites-only switch, and the search box each changing what is shown — one screenshot per control, or one screenshot plus a short note, is fine.",
        "Summary: the Recipes, Favorites and Total time values and the category breakdown visible, with more than one category represented.",
        "Detail screen — view mode: one recipe’s full details (name, category, difficulty, cook time, servings, notes).",
        "Detail screen — edit mode, validation: an edit submitted with bad input, showing the error messages.",
        "Detail screen — after Save: showing the edited values now saved.",
        "Favorite toggle and Delete: a before/after pair showing the star toggled, and a recipe deleted and gone from the list.",
        "Empty state: the List screen with the text No recipes found — easiest to capture with a second, fresh test account before it has any recipes.",
    ]

    for i, caption in enumerate(screenshots, 1):
        # Screenshot box / placeholder
        table = doc.add_table(rows=1, cols=1)
        table.alignment = docx.enum.table.WD_TABLE_ALIGNMENT.CENTER
        cell = table.cell(0, 0)
        cell.width = Inches(5.5)
        p_cell = cell.paragraphs[0]
        p_cell.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r_box = p_cell.add_run(f"\n[ INSERT SCREENSHOT {i} HERE ]\n")
        r_box.font.color.rgb = RGBColor(120, 120, 120)
        r_box.font.italic = True

        # Caption
        p_cap = doc.add_paragraph()
        p_cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r_cap = p_cap.add_run(f"Figure {i}: {caption}")
        r_cap.font.size = Pt(10)
        r_cap.font.italic = True
        r_cap.bold = True
        p_cap.paragraph_format.space_after = Pt(18)

    doc.save(f"{student_code}.docx")
    print(f"Report generated successfully as {student_code}.docx")

if __name__ == "__main__":
    import sys
    code = sys.argv[1] if len(sys.argv) > 1 else "QE190111"
    name = sys.argv[2] if len(sys.argv) > 2 else "Nguyen Van A"
    create_report(code, name)
