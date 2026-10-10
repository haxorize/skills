# Right on purpose: a .py inside a selftest's fixture directory. It is data the
# selftest feeds paired-bundled.py, not a script, so the walk must stop one
# level down. A recursive walk (`find src/*/scripts`, or `src/*/scripts/*/*.py`)
# reaches it, and it has no conventions pointer and no selftest, so the clean
# root reds.
print("fixture input")
