# Fixture only — never executed.
# ok: sh-envdump
home = os.environ.get("HOME")
# ok: sh-noverify
resp = requests.get(url, verify=True)
# A whole Cyrillic word beside ASCII, and a Greek letter on its own.
# ok: uni-confusable
москва_data = 0
# ok: uni-confusable
τ_max = 1

# A regex range, a unit, and the ASCII tail of an escape beside a Cyrillic word.
# ok: uni-confusable
WORD = re.compile(r"[A-Za-zА-Яа-яЁё]+")
# ok: uni-confusable
εr = 4.4
# ok: uni-confusable
print("\\nОтвет: \\u0442о \\bслово \\ufeffответ")
