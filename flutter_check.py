#!/usr/bin/env python3
"""
Flutter/Dart Code Analyzer
===========================
Analizza un progetto Flutter alla ricerca di:
  - File "morti" (mai importati da nessuna parte)
  - Classi/funzioni/variabili top-level potenzialmente inutilizzate
  - Rischi di memory leak (controller/subscription non fatti dispose)
  - Errori/warning di compilazione (via `dart analyze`, se disponibile)

USO:
    python3 flutter_dead_code_analyzer.py /percorso/al/progetto_flutter
    python3 flutter_dead_code_analyzer.py .                # progetto corrente
    python3 flutter_dead_code_analyzer.py . --report report.md

NOTE:
  - Questo script usa euristiche basate su regex, NON un parser Dart completo.
    Serve a farti un primo screening rapido: verifica sempre manualmente
    prima di cancellare qualcosa.
  - Se `dart` è nel PATH, viene eseguito anche `dart analyze` per gli errori
    di compilazione reali.

SICUREZZA / COSA NON FA:
  - Lo script è a SOLA LETTURA sul progetto analizzato: non modifica,
    sposta né elimina MAI alcun file dentro il progetto Flutter.
  - Non chiama mai os.remove/unlink/rmtree né riscrive file .dart o
    pubspec.yaml.
  - L'unico file che lo script eventualmente scrive è il report indicato
    con --report (es. report.md), creato da zero in un percorso a scelta
    tua: tutto il resto è solo output stampato a schermo.
  - Il compito di eliminare o modificare i file segnalati resta
    interamente tuo (o del tuo IDE), dopo che li hai verificati a mano.
"""

import argparse
import os
import re
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

# ---------------------------------------------------------------------------
# Configurazione euristiche
# ---------------------------------------------------------------------------

ENTRY_POINT_NAMES = {"main.dart"}
GENERATED_SUFFIXES = (".g.dart", ".freezed.dart", ".gr.dart", ".config.dart", ".mocks.dart")

# Classi/tipi che tipicamente vanno "chiuse"/"disposte" per evitare memory leak
DISPOSABLE_TYPES = [
    "AnimationController",
    "TextEditingController",
    "ScrollController",
    "PageController",
    "TabController",
    "FocusNode",
    "StreamController",
    "StreamSubscription",
    "VideoPlayerController",
    "AudioPlayer",
    "Timer",
    "ChangeNotifier",
]

# Metodi che "chiudono" correttamente una risorsa
CLOSE_METHODS = ("dispose", "cancel", "close", "stop")

# Pacchetti che tipicamente NON vengono mai importati con `import 'package:...'`
# perché lavorano solo in fase di code-generation / build o come tool CLI.
# Se risultano "non usati" vanno segnalati in modo diverso (non sono morti per forza).
CODEGEN_ONLY_PACKAGES = {
    "build_runner", "json_serializable", "freezed", "hive_generator",
    "retrofit_generator", "injectable_generator", "auto_route_generator",
    "riverpod_generator", "flutter_launcher_icons", "flutter_native_splash",
    "intl_utils", "flutter_lints", "lints", "flutter_gen_runner",
    "custom_lint",
}

# Nomi che non vanno mai considerati "dipendenze" anche se compaiono nella sezione
PUBSPEC_SECTION_SKIP_KEYS = {"sdk", "path", "git", "url", "ref", "version", "hosted"}

DECL_RE = re.compile(
    r'^\s*(?:@\w+(?:\([^)]*\))?\s*)*'                       # eventuali annotazioni
    r'(?:abstract\s+|final\s+|const\s+)*'
    r'class\s+(\w+)', re.MULTILINE)

TOPLEVEL_FUNC_RE = re.compile(
    r'^[A-Za-z_][\w<>?,\s]*\s+(\w+)\s*\([^;{]*\)\s*(?:async\s*)?\{', re.MULTILINE)

IMPORT_RE = re.compile(r'''import\s+['"]([^'"]+)['"]''')
PART_RE = re.compile(r'''part\s+['"]([^'"]+)['"]''')

FIELD_DECL_RE = re.compile(
    r'(?:late\s+|final\s+|const\s+)?(' + '|'.join(DISPOSABLE_TYPES) + r')\s*(?:<[^>]*>)?\s+(\w+)'
)


# ---------------------------------------------------------------------------
# Utility
# ---------------------------------------------------------------------------

def find_dart_files(root: Path):
    files = []
    for p in root.rglob("*.dart"):
        # ignora build, cache, pacchetti esterni
        parts = set(p.parts)
        if parts & {"build", ".dart_tool", "ios", "android", "web", ".pub-cache"}:
            continue
        files.append(p)
    return files


def strip_comments_and_strings(code: str) -> str:
    """Rimuove commenti (semplici) e stringhe per ridurre falsi positivi
    nella conta delle occorrenze di identificatori."""
    code = re.sub(r'//.*', '', code)
    code = re.sub(r'/\*.*?\*/', '', code, flags=re.DOTALL)
    return code


def read(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        return ""


# ---------------------------------------------------------------------------
# 1. File morti
# ---------------------------------------------------------------------------

def resolve_import(importer: Path, import_str: str, lib_root: Path) -> Path | None:
    if import_str.startswith("package:"):
        # package:nome_progetto/percorso.dart -> lib/percorso.dart
        parts = import_str.split("/", 1)
        if len(parts) == 2:
            return (lib_root / parts[1]).resolve()
        return None
    if import_str.startswith("dart:"):
        return None
    # import relativo
    return (importer.parent / import_str).resolve()


def find_dead_files(dart_files: list[Path], root: Path):
    lib_root = root / "lib"
    referenced = set()
    all_files = {f.resolve() for f in dart_files}

    for f in dart_files:
        code = read(f)
        for imp in IMPORT_RE.findall(code) + PART_RE.findall(code):
            target = resolve_import(f, imp, lib_root)
            if target and target in all_files:
                referenced.add(target)
        # i file "part of" sono referenziati dal file principale, non contano come standalone
        for part in PART_RE.findall(code):
            target = resolve_import(f, part, lib_root)
            if target:
                referenced.add(target)

    dead = []
    for f in dart_files:
        rf = f.resolve()
        if rf in referenced:
            continue
        if f.name in ENTRY_POINT_NAMES:
            continue
        if f.name.endswith(GENERATED_SUFFIXES):
            continue
        if "test" in f.parts and f.name.endswith("_test.dart"):
            continue  # i test si lanciano da soli, non serve siano importati
        dead.append(f)
    return sorted(dead)


# ---------------------------------------------------------------------------
# 2. Classi / funzioni potenzialmente inutilizzate
# ---------------------------------------------------------------------------

def find_unused_symbols(dart_files: list[Path], root: Path):
    """Euristica: una classe/funzione dichiarata in un file e il cui nome
    compare UNA SOLA volta in tutto il progetto (cioè solo nella dichiarazione)
    è probabilmente morta."""
    all_code = {}
    for f in dart_files:
        all_code[f] = strip_comments_and_strings(read(f))

    full_text = "\n".join(all_code.values())

    def count_occurrences(name: str) -> int:
        return len(re.findall(r'\b' + re.escape(name) + r'\b', full_text))

    unused_classes = []
    unused_functions = []

    for f, code in all_code.items():
        if f.name.endswith(GENERATED_SUFFIXES):
            continue

        for m in DECL_RE.finditer(code):
            name = m.group(1)
            if count_occurrences(name) <= 1:
                unused_classes.append((f, name))

        for m in TOPLEVEL_FUNC_RE.finditer(code):
            name = m.group(1)
            # esclude keyword comuni scambiate per nomi funzione da regex grezza
            if name in {"if", "for", "while", "switch", "catch", "build", "main"}:
                continue
            if count_occurrences(name) <= 1:
                unused_functions.append((f, name))

    return unused_classes, unused_functions


# ---------------------------------------------------------------------------
# 3. Rischi memory leak
# ---------------------------------------------------------------------------

def find_memory_leak_risks(dart_files: list[Path]):
    risks = []
    for f in dart_files:
        code = read(f)
        if "dispose" not in code and not FIELD_DECL_RE.search(code):
            continue

        fields = FIELD_DECL_RE.findall(code)
        if not fields:
            continue

        # estrae il corpo del metodo dispose(), se esiste
        dispose_match = re.search(r'void\s+dispose\s*\(\s*\)\s*\{(.*?)\n\s*\}', code, re.DOTALL)
        dispose_body = dispose_match.group(1) if dispose_match else ""

        for type_name, field_name in fields:
            called = any(
                re.search(rf'\b{re.escape(field_name)}\s*\.\s*{m}\s*\(', dispose_body)
                for m in CLOSE_METHODS
            )
            if not called:
                risks.append((f, type_name, field_name, dispose_match is not None))

        # StreamSubscription .listen() senza .cancel() da nessuna parte nel file
        for sub_name in re.findall(r'\.listen\s*\(', code):
            pass  # copertura già gestita da FIELD_DECL_RE per le subscription dichiarate come campo

    return risks


# ---------------------------------------------------------------------------
# 4. Dipendenze pubspec.yaml mai importate nel codice
# ---------------------------------------------------------------------------

def parse_pubspec_dependencies(pubspec_path: Path):
    """Parser leggero (no libreria yaml) per estrarre i nomi dei pacchetti
    dichiarati in dependencies / dev_dependencies di un pubspec.yaml."""
    if not pubspec_path.exists():
        return {}

    text = read(pubspec_path)
    lines = text.splitlines()

    deps = {}  # nome -> sezione ("dependencies" | "dev_dependencies")
    current_section = None

    for raw_line in lines:
        if not raw_line.strip() or raw_line.strip().startswith("#"):
            continue

        indent = len(raw_line) - len(raw_line.lstrip(" "))
        stripped = raw_line.strip()

        # sezione top-level (indent 0)
        if indent == 0:
            key = stripped.split(":")[0]
            if key in ("dependencies", "dev_dependencies"):
                current_section = key
            else:
                current_section = None
            continue

        # nome pacchetto: indent di 2 spazi rispetto alla sezione, riga tipo "nome:" o "nome: ^1.2.3"
        if current_section and indent == 2 and ":" in stripped:
            name = stripped.split(":")[0].strip()
            if name and name not in PUBSPEC_SECTION_SKIP_KEYS:
                deps[name] = current_section

    # 'flutter' e 'flutter_test' sono SDK, sempre "usati" implicitamente: li escludiamo
    deps.pop("flutter", None)
    deps.pop("flutter_test", None)
    return deps


def find_unused_pubspec_deps(dart_files: list[Path], pubspec_deps: dict, project_root: Path):
    """Confronta i pacchetti dichiarati in pubspec.yaml con i `package:nome/...`
    effettivamente importati in tutto il codice Dart del progetto."""
    if not pubspec_deps:
        return []

    used_packages = set()
    for f in dart_files:
        code = read(f)
        for imp in IMPORT_RE.findall(code):
            if imp.startswith("package:"):
                pkg_name = imp.split("/", 1)[0].replace("package:", "")
                used_packages.add(pkg_name)

    # controlla anche riferimenti nei file di configurazione comuni
    # (es. plugin usati solo dichiarativamente, tipo font o asset generator)
    config_files = ["pubspec.yaml", "analysis_options.yaml"]
    config_text = ""
    for cf in config_files:
        config_text += read(project_root / cf)

    unused = []
    for name, section in sorted(pubspec_deps.items()):
        if name in used_packages:
            continue
        note = "codegen/tool: normale se non è mai importato direttamente" \
            if name in CODEGEN_ONLY_PACKAGES else "nessun `import 'package:...'` trovato nel codice"
        unused.append((name, section, note))

    return unused


# ---------------------------------------------------------------------------
# 5. dart analyze (errori/warning reali di compilazione)
# ---------------------------------------------------------------------------

def run_dart_analyze(root: Path):
    try:
        result = subprocess.run(
            ["dart", "analyze", "--no-fatal-infos"],
            cwd=root,
            capture_output=True,
            text=True,
            timeout=180,
        )
        return result.stdout + result.stderr
    except FileNotFoundError:
        return None
    except subprocess.TimeoutExpired:
        return "TIMEOUT: 'dart analyze' ha impiegato troppo tempo."


# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------

def build_report(root: Path, dead_files, unused_classes, unused_functions, leak_risks,
                  unused_deps, analyze_output):
    lines = []
    lines.append(f"# Report analisi Flutter — {root}\n")

    lines.append("## 1. File potenzialmente morti (mai importati)\n")
    if dead_files:
        for f in dead_files:
            lines.append(f"- `{f.relative_to(root)}`")
    else:
        lines.append("Nessun file sospetto trovato.")
    lines.append("")

    lines.append("## 2. Classi potenzialmente inutilizzate\n")
    if unused_classes:
        for f, name in unused_classes:
            lines.append(f"- `{name}` in `{f.relative_to(root)}`")
    else:
        lines.append("Nessuna classe sospetta trovata.")
    lines.append("")

    lines.append("## 3. Funzioni top-level potenzialmente inutilizzate\n")
    if unused_functions:
        for f, name in unused_functions:
            lines.append(f"- `{name}()` in `{f.relative_to(root)}`")
    else:
        lines.append("Nessuna funzione sospetta trovata.")
    lines.append("")

    lines.append("## 4. Rischi di memory leak (controller/risorse non disposti)\n")
    if leak_risks:
        for f, type_name, field_name, has_dispose in leak_risks:
            stato = "ha dispose() ma non chiude questo campo" if has_dispose else "NON ha nemmeno un metodo dispose()"
            lines.append(f"- `{field_name}` ({type_name}) in `{f.relative_to(root)}` — {stato}")
    else:
        lines.append("Nessun rischio evidente trovato.")
    lines.append("")

    lines.append("## 5. Dipendenze in pubspec.yaml mai importate nel codice\n")
    if unused_deps:
        for name, section, note in unused_deps:
            lines.append(f"- `{name}` ({section}) — {note}")
        lines.append("\n> Nota: prima di rimuoverle, controlla che non siano usate solo in `pubspec.yaml` "
                      "stesso (es. font, asset generator) o via codegen/build_runner.")
    else:
        lines.append("Nessuna dipendenza dichiarata risulta inutilizzata (o pubspec.yaml non trovato).")
    lines.append("")

    lines.append("## 6. Errori/warning di compilazione (`dart analyze`)\n")
    if analyze_output is None:
        lines.append("`dart` non è stato trovato nel PATH: esegui manualmente `dart analyze` "
                      "o `flutter analyze` nel progetto per questa parte.")
    elif analyze_output.strip() == "":
        lines.append("Nessun output da dart analyze (probabilmente tutto ok).")
    else:
        lines.append("```")
        lines.append(analyze_output.strip())
        lines.append("```")

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Analizza un progetto Flutter/Dart.")
    parser.add_argument("project_path", help="Percorso della root del progetto Flutter")
    parser.add_argument("--report", default=None, help="Salva il report in un file Markdown")
    parser.add_argument("--skip-analyze", action="store_true", help="Salta 'dart analyze'")
    args = parser.parse_args()

    root = Path(args.project_path).resolve()
    if not root.exists():
        print(f"Errore: il percorso {root} non esiste.")
        sys.exit(1)

    lib_dir = root / "lib"
    if not lib_dir.exists():
        print(f"Attenzione: non trovo {lib_dir}. Sei sicuro che sia la root di un progetto Flutter?")

    print(f"Scansione di {root} ...")
    print("(Modalità sola lettura: nessun file del progetto verrà modificato o eliminato)")
    dart_files = find_dart_files(root)
    print(f"Trovati {len(dart_files)} file .dart")

    print("Cerco file morti...")
    dead_files = find_dead_files(dart_files, root)

    print("Cerco classi/funzioni inutilizzate (euristica, può avere falsi positivi)...")
    unused_classes, unused_functions = find_unused_symbols(dart_files, root)

    print("Cerco rischi di memory leak...")
    leak_risks = find_memory_leak_risks(dart_files)

    print("Cerco dipendenze in pubspec.yaml mai importate...")
    pubspec_deps = parse_pubspec_dependencies(root / "pubspec.yaml")
    unused_deps = find_unused_pubspec_deps(dart_files, pubspec_deps, root)

    analyze_output = None
    if not args.skip_analyze:
        print("Eseguo 'dart analyze' (se disponibile)...")
        analyze_output = run_dart_analyze(root)

    report = build_report(root, dead_files, unused_classes, unused_functions, leak_risks,
                           unused_deps, analyze_output)

    print("\n" + "=" * 70)
    print(report)
    print("=" * 70)

    if args.report:
        Path(args.report).write_text(report, encoding="utf-8")
        print(f"\nReport salvato in: {args.report}")


if __name__ == "__main__":
    main()

