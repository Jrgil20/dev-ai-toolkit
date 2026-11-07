#!/usr/bin/env python3
"""Herramienta de mantenimiento de dev-ai-toolkit.

Subcomandos:
  validate   Valida frontmatter (spec agentskills.io), fechas de metadata,
             archivos referenciados, SOURCE.md de vendor/, submódulos de external/
             y el catálogo de comunidad. Reporta lo vencido y lo que vence pronto.
  catalog    Genera CATALOG.md con fechas y estado de vigencia de todo el kit.
  external   Compara cada submódulo de external/ con su rama upstream (requiere red)
             y dice si está al día o cuántos commits va atrasado.

Uso:
  python3 scripts/toolkit.py validate [--fail-on-stale] [--today YYYY-MM-DD]
  python3 scripts/toolkit.py catalog  [--today YYYY-MM-DD]
  python3 scripts/toolkit.py external [--fail-if-behind]

Requiere: Python 3.9+, PyYAML (pip install pyyaml) y git (para fechas de agentes).
"""
from __future__ import annotations

import argparse
import datetime as dt
import re
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path

try:
    import yaml
except ImportError:  # pragma: no cover
    sys.exit("Falta PyYAML: pip install pyyaml")

ROOT = Path(__file__).resolve().parent.parent
NAME_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
# Ventana de revisión (meses) según qué tan rápido envejece el contenido.
VOLATILITY_MONTHS = {"conceptual": 12, "tooling": 6, "pricing": 3}
STATUSES = {"active", "incomplete", "deprecated"}
OWN_META_KEYS = ["added", "updated", "review-by", "volatility", "status", "lang", "origin"]
SOURCE_KEYS = ["upstream-repo", "upstream-path", "upstream-commit", "upstream-commit-date",
               "license", "synced", "review-by", "modified"]
COMMUNITY_KEYS = ["id", "repo", "kind", "license", "upstream-commit", "upstream-commit-date",
                  "verified", "review-by", "vendored", "recommended", "install"]
SOON_DAYS = 30
SKIP_DATE_TAG = "[skip-date]"
AGENT_MONTHS = 6
# Rutas relativas mencionadas en un SKILL.md (references/x.md, scripts/y.py, assets/z).
REF_RE = re.compile(r"(?<![\w/.-])((?:references|scripts|assets)/[\w./-]+\.[A-Za-z0-9]+)")


# --------------------------------------------------------------------------- utilidades
def parse_date(value: str) -> dt.date:
    return dt.date.fromisoformat(value)


def is_date(value) -> bool:
    """True si `value` es un string 'YYYY-MM-DD' que además es una fecha real."""
    if not isinstance(value, str) or not DATE_RE.fullmatch(value):
        return False
    try:
        parse_date(value)
    except ValueError:
        return False
    return True


def add_months(d: dt.date, months: int) -> dt.date:
    y, m = divmod(d.month - 1 + months, 12)
    year, month = d.year + y, m + 1
    for day in (d.day, 30, 29, 28):
        try:
            return dt.date(year, month, day)
        except ValueError:
            continue
    raise ValueError(d)


def read_frontmatter(path: Path) -> tuple[dict, str]:
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        raise ValueError("no empieza con frontmatter '---'")
    end = text.find("\n---", 4)
    if end == -1:
        raise ValueError("frontmatter sin cierre '---'")
    data = yaml.safe_load(text[4:end]) or {}
    if not isinstance(data, dict):
        raise ValueError("frontmatter no es un mapa YAML")
    return data, text[end + 4:]


def git_dates(path: Path) -> tuple[str | None, str | None]:
    """(primer commit, último commit) que tocan `path`, o (None, None) sin historial.

    Ignora commits cuyo mensaje contiene SKIP_DATE_TAG (movimientos, cambios solo de
    metadata, formato): no cambian el contenido, así que no cuentan como "actualizado".
    """
    try:
        out = subprocess.run(
            ["git", "log", "--follow", "--format=%cs", "--invert-grep", "--fixed-strings",
             f"--grep={SKIP_DATE_TAG}", "--", str(path.relative_to(ROOT))],
            cwd=ROOT, capture_output=True, text=True, check=True,
        ).stdout.split()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None, None
    return (out[-1], out[0]) if out else (None, None)


def git(*args: str, cwd: Path = ROOT) -> str | None:
    try:
        return subprocess.run(["git", *args], cwd=cwd, capture_output=True, text=True,
                              check=True).stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None


def submodules() -> list[dict]:
    """Submódulos declarados en .gitmodules: path, url, branch y commit fijado (gitlink)."""
    if not (ROOT / ".gitmodules").exists():
        return []
    raw = git("config", "-f", ".gitmodules", "--get-regexp", r"^submodule\..*\.(path|url|branch)$")
    mods: dict[str, dict] = {}
    for line in (raw or "").splitlines():
        key, value = line.split(" ", 1)
        name, field_ = key[len("submodule."):].rsplit(".", 1)
        mods.setdefault(name, {})[field_] = value
    out = []
    for name, m in sorted(mods.items()):
        path = m.get("path", name)
        pinned = None
        tree = git("ls-tree", "HEAD", path)          # "160000 commit <sha>\t<path>"
        if tree and tree.split()[1] == "commit":
            pinned = tree.split()[2]
        else:                                        # aún no commiteado: usar el índice
            staged = git("ls-files", "-s", path)
            if staged and staged.startswith("160000"):
                pinned = staged.split()[1]
        out.append({"name": name, "path": path, "url": m.get("url", ""),
                    "branch": m.get("branch", ""), "pinned": pinned,
                    "initialized": (ROOT / path / ".git").exists()})
    return out


def freshness(review_by: str, today: dt.date, status: str = "active") -> str:
    if status == "deprecated":
        return "🗄️ obsoleto"
    if status == "incomplete":
        return "🚧 incompleto"
    days = (parse_date(review_by) - today).days
    if days < 0:
        return f"⛔ vencido ({-days} d)"
    if days <= SOON_DAYS:
        return f"⚠️ vence en {days} d"
    return "✅ vigente"


# --------------------------------------------------------------------------- modelo
@dataclass
class Item:
    kind: str            # own | standalone | vendor | community | agent
    name: str
    path: str
    added: str = ""
    updated: str = ""
    review_by: str = ""
    status: str = "active"
    volatility: str = ""
    lang: str = ""
    origin: str = ""
    license: str = ""
    extra: dict = field(default_factory=dict)


@dataclass
class Report:
    errors: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)
    stale: list[str] = field(default_factory=list)
    soon: list[str] = field(default_factory=list)

    def err(self, where: str, msg: str):
        self.errors.append(f"{where}: {msg}")

    def warn(self, where: str, msg: str):
        self.warnings.append(f"{where}: {msg}")


# --------------------------------------------------------------------------- validaciones
def check_spec(skill_dir: Path, fm: dict, rep: Report, where: str):
    name = fm.get("name")
    if not isinstance(name, str) or not NAME_RE.fullmatch(name) or len(name) > 64:
        rep.err(where, f"name inválido: {name!r}")
    elif name != skill_dir.name:
        rep.err(where, f"name '{name}' no coincide con la carpeta '{skill_dir.name}'")
    desc = fm.get("description")
    if not isinstance(desc, str) or not desc.strip():
        rep.err(where, "description vacía o ausente")
    elif len(desc) > 1024:
        rep.err(where, f"description excede 1024 caracteres ({len(desc)})")
    comp = fm.get("compatibility")
    if comp is not None and (not isinstance(comp, str) or len(comp) > 500):
        rep.err(where, "compatibility debe ser texto de ≤500 caracteres")
    meta = fm.get("metadata")
    if meta is not None and (not isinstance(meta, dict)
                             or not all(isinstance(v, str) for v in meta.values())):
        rep.err(where, "metadata debe ser un mapa de strings (citar las fechas)")


def check_body(skill_dir: Path, body: str, rep: Report, where: str):
    lines = body.count("\n")
    if lines > 500:
        rep.warn(where, f"SKILL.md tiene {lines} líneas (>500 recomendado por el spec)")
    missing = sorted({r for r in REF_RE.findall(body) if not (skill_dir / r).exists()})
    for ref in missing:
        rep.warn(where, f"referencia a archivo inexistente: {ref}")


def check_dates(meta: dict, rep: Report, where: str, today: dt.date) -> bool:
    ok = True
    for key in ("added", "updated", "review-by"):
        if not is_date(meta.get(key)):
            rep.err(where, f"metadata.{key} debe ser una fecha 'YYYY-MM-DD' válida entre comillas")
            ok = False
    if not ok:
        return False
    added, updated, review = (parse_date(meta[k]) for k in ("added", "updated", "review-by"))
    if added > updated:
        rep.err(where, "added es posterior a updated")
    if updated > today:
        rep.err(where, "updated está en el futuro")
    if review <= updated:
        rep.err(where, "review-by debe ser posterior a updated")
    months = VOLATILITY_MONTHS.get(meta.get("volatility", ""))
    if months and review > add_months(updated, months):
        rep.warn(where, f"review-by excede la ventana de {months} meses para "
                        f"volatility={meta['volatility']}")
    return True


def load_own(base: str, kind: str, rep: Report, today: dt.date) -> list[Item]:
    items = []
    for skill_md in sorted((ROOT / base).glob("*/SKILL.md")):
        sdir = skill_md.parent
        where = str(skill_md.relative_to(ROOT))
        try:
            fm, body = read_frontmatter(skill_md)
        except ValueError as exc:
            rep.err(where, str(exc))
            continue
        check_spec(sdir, fm, rep, where)
        check_body(sdir, body, rep, where)
        meta = fm.get("metadata") or {}
        for key in OWN_META_KEYS:
            if key not in meta:
                rep.err(where, f"falta metadata.{key}")
        if meta.get("status") not in STATUSES:
            rep.err(where, f"metadata.status debe ser uno de {sorted(STATUSES)}")
        if meta.get("volatility") not in VOLATILITY_MONTHS:
            rep.err(where, f"metadata.volatility debe ser uno de {sorted(VOLATILITY_MONTHS)}")
        if not check_dates(meta, rep, where, today):
            continue
        _, last_commit = git_dates(sdir)
        if last_commit and last_commit > meta["updated"]:
            rep.warn(where, f"último commit ({last_commit}) es posterior a metadata.updated "
                            f"({meta['updated']}): ¿olvidaste actualizar la fecha?")
        item = Item(kind, fm.get("name", sdir.name), str(sdir.relative_to(ROOT)),
                    meta["added"], meta["updated"], meta["review-by"],
                    meta.get("status", ""), meta.get("volatility", ""),
                    meta.get("lang", ""), meta.get("origin", ""), fm.get("license", ""))
        items.append(item)
    return items


def load_vendor(rep: Report, today: dt.date) -> list[Item]:
    items = []
    for skill_md in sorted((ROOT / "vendor").glob("*/SKILL.md")):
        sdir = skill_md.parent
        where = str(sdir.relative_to(ROOT))
        try:
            fm, body = read_frontmatter(skill_md)
        except ValueError as exc:
            rep.err(where, f"SKILL.md: {exc}")
            continue
        check_spec(sdir, fm, rep, where)
        check_body(sdir, body, rep, where)
        n_errors = len(rep.errors)
        source = sdir / "SOURCE.md"
        if not source.exists():
            rep.err(where, "falta SOURCE.md (origen, commit y licencia)")
            continue
        try:
            src, _ = read_frontmatter(source)
        except ValueError as exc:
            rep.err(where, f"SOURCE.md: {exc}")
            continue
        for key in SOURCE_KEYS:
            if key not in src:
                rep.err(where, f"SOURCE.md sin '{key}'")
        if not any(sdir.glob("LICENSE*")) and "sin archivo" not in str(src.get("license", "")) \
                and "no incluye" not in str(src.get("license", "")):
            rep.warn(where, "no hay archivo LICENSE* junto a la copia")
        for key in ("synced", "review-by", "upstream-commit-date"):
            if not is_date(str(src.get(key, ""))):
                rep.err(where, f"SOURCE.md: {key} debe ser una fecha 'YYYY-MM-DD' válida")
        if len(rep.errors) > n_errors:
            continue
        items.append(Item("vendor", fm.get("name", sdir.name), where,
                          added=src["synced"], updated=src["upstream-commit-date"],
                          review_by=src["review-by"], origin=src["upstream-repo"],
                          license=src["license"],
                          extra={"commit": str(src["upstream-commit"])[:7]}))
    return items


def load_community(rep: Report, vendor_names: set[str]) -> tuple[list[Item], dict[str, dict]]:
    path = ROOT / "catalog" / "community.yaml"
    where = "catalog/community.yaml"
    if not path.exists():
        rep.err(where, "no existe")
        return [], {}
    data = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    items, seen, entries = [], set(), {}
    for entry in data.get("entries", []):
        eid = entry.get("id", "?")
        entries[eid] = entry
        w = f"{where}#{eid}"
        for key in COMMUNITY_KEYS:
            if key not in entry:
                rep.err(w, f"falta '{key}'")
        if eid in seen:
            rep.err(w, "id duplicado")
        seen.add(eid)
        dates_ok = True
        for key in ("verified", "review-by", "upstream-commit-date"):
            if not is_date(entry.get(key)):
                rep.err(w, f"{key} debe ser una fecha 'YYYY-MM-DD' válida entre comillas")
                dates_ok = False
        for v in entry.get("vendored") or []:
            if v not in vendor_names:
                rep.err(w, f"declara vendored '{v}' pero no existe vendor/{v}/")
        sub = entry.get("submodule")
        if sub and sub not in {s["path"] for s in submodules()}:
            rep.err(w, f"declara submodule '{sub}' pero no está en .gitmodules")
        if dates_ok:
            items.append(Item("community", eid, entry.get("repo", ""),
                              updated=str(entry.get("upstream-commit-date", "")),
                              review_by=entry["review-by"], license=entry.get("license", ""),
                              extra={"verified": entry.get("verified", ""),
                                     "commit": entry.get("upstream-commit", ""),
                                     "version": entry.get("upstream-version", "n/a"),
                                     "vendored": entry.get("vendored") or [],
                                     "submodule": entry.get("submodule", ""),
                                     "recommended": [r.get("name") for r in
                                                     entry.get("recommended") or []]}))
    return items, entries


def load_external(rep: Report, community: dict[str, dict]) -> list[Item]:
    """Skills que llegan por submódulo git (external/). Las fechas de revisión salen de
    la entrada de catalog/community.yaml que declara `submodule: <path>`."""
    by_path = {e.get("submodule"): e for e in community.values() if e.get("submodule")}
    items = []
    for sm in submodules():
        where = sm["path"]
        entry = by_path.get(where)
        if entry is None:
            rep.err(where, "submódulo sin entrada en catalog/community.yaml (campo submodule)")
            continue
        if not sm["branch"]:
            rep.warn(where, "sin 'branch' en .gitmodules: `git submodule update --remote` "
                            "no sabrá qué rama seguir")
        if sm["pinned"] and not sm["pinned"].startswith(str(entry.get("upstream-commit", "-"))):
            rep.warn(where, f"el submódulo apunta a {sm['pinned'][:7]} pero el catálogo dice "
                            f"{entry.get('upstream-commit')}: revisa el cambio y actualiza "
                            "upstream-commit, upstream-commit-date, verified y review-by")
        if not sm["initialized"]:
            rep.warn(where, "submódulo no inicializado: git submodule update --init")
            skill_dirs = []
        else:
            skill_dirs = sorted(p.parent for p in (ROOT / where).glob("skills/*/SKILL.md")) \
                or sorted(p.parent for p in (ROOT / where).glob("SKILL.md"))
            if not skill_dirs:
                rep.err(where, "el submódulo no contiene ningún SKILL.md")
        for sdir in skill_dirs:
            w = str(sdir.relative_to(ROOT))
            try:
                fm, body = read_frontmatter(sdir / "SKILL.md")
            except ValueError as exc:
                rep.err(w, str(exc))
                continue
            check_spec(sdir, fm, rep, w)
            check_body(sdir, body, rep, w)
            commit_date = git("log", "-1", "--format=%cs", cwd=ROOT / where) or ""
            items.append(Item("external", fm.get("name", sdir.name), w,
                              updated=commit_date, review_by=entry["review-by"],
                              origin=f"https://github.com/{entry.get('repo', '')}",
                              license=entry.get("license", ""),
                              extra={"commit": (sm["pinned"] or "")[:7], "branch": sm["branch"],
                                     "verified": entry.get("verified", ""),
                                     "submodule": where}))
    return items


def load_agents(rep: Report) -> list[Item]:
    items = []
    for agent in sorted((ROOT / "adapters" / "claude-code" / "agents").glob("*.md")):
        where = str(agent.relative_to(ROOT))
        try:
            fm, _ = read_frontmatter(agent)
        except ValueError as exc:
            rep.err(where, str(exc))
            continue
        first, last = git_dates(agent)
        if not last:
            rep.warn(where, "sin historial git: no se pueden derivar fechas")
            continue
        review = add_months(parse_date(last), AGENT_MONTHS).isoformat()
        items.append(Item("agent", fm.get("name", agent.stem), where, first, last, review,
                          volatility="tooling",
                          extra={"model": fm.get("model", ""), "skills": fm.get("skills") or []}))
    return items


def collect(today: dt.date) -> tuple[list[Item], Report]:
    rep = Report()
    items = load_own("skills", "own", rep, today)
    items += load_own("standalone", "standalone", rep, today)
    vendor = load_vendor(rep, today)
    items += vendor
    community, entries = load_community(
        rep, {d.name for d in (ROOT / "vendor").glob("*/") if d.is_dir()})
    items += community
    items += load_external(rep, entries)
    items += load_agents(rep)
    names = [i.name for i in items if i.kind in ("own", "standalone", "vendor", "external")]
    for dup in sorted({n for n in names if names.count(n) > 1}):
        rep.err("kit", f"nombre de skill duplicado entre carpetas: {dup}")
    for it in items:
        if it.status in ("incomplete", "deprecated") or not it.review_by:
            if it.status == "incomplete":
                rep.warn(it.path, "marcado como incompleto (metadata.status=incomplete)")
            continue
        days = (parse_date(it.review_by) - today).days
        label = f"[{it.kind}] {it.name} — review-by {it.review_by}"
        if days < 0:
            rep.stale.append(f"{label} (vencido hace {-days} días)")
        elif days <= SOON_DAYS:
            rep.soon.append(f"{label} (vence en {days} días)")
    return items, rep


# --------------------------------------------------------------------------- CATALOG.md
def render_catalog(items: list[Item], today: dt.date) -> str:
    def rows(kind):
        return sorted((i for i in items if i.kind == kind), key=lambda i: i.name)

    out = [
        "# Catálogo de dev-ai-toolkit",
        "",
        f"> Generado por `python3 scripts/toolkit.py catalog` el **{today.isoformat()}**. "
        "No editar a mano: la fuente de verdad es el frontmatter de cada skill, "
        "`vendor/*/SOURCE.md`, `catalog/community.yaml`, `.gitmodules` y el historial git.",
        ">",
        "> **Estado**: ✅ vigente · ⚠️ vence en ≤30 días · ⛔ vencido (revisar/actualizar) · "
        "🚧 incompleto · 🗄️ obsoleto. Ventanas de revisión: conceptual 12 meses, "
        "tooling 6, pricing 3, vendor/comunidad 3.",
        "",
        "## Skills propios (`skills/`)",
        "",
        "| Skill | Idioma | Volatilidad | Agregado | Actualizado | Revisar antes de | Estado |",
        "|---|---|---|---|---|---|---|",
    ]
    for i in rows("own"):
        out.append(f"| [`{i.name}`]({i.path}/SKILL.md) | {i.lang} | {i.volatility} | {i.added} "
                   f"| {i.updated} | {i.review_by} | {freshness(i.review_by, today, i.status)} |")
    out += ["", "## Skills autocontenidos (`standalone/`)", "",
            "Se instalan aparte (submódulo o copia manual); `install.sh` no los enlaza.", "",
            "| Skill | Idioma | Volatilidad | Agregado | Actualizado | Revisar antes de | Estado |",
            "|---|---|---|---|---|---|---|"]
    for i in rows("standalone"):
        out.append(f"| [`{i.name}`]({i.path}/SKILL.md) | {i.lang} | {i.volatility} | {i.added} "
                   f"| {i.updated} | {i.review_by} | {freshness(i.review_by, today, i.status)} |")
    out += ["", "## Skills de terceros copiados (`vendor/`)", "",
            "Copias sin modificar, fijadas a un commit. Ver `SOURCE.md` en cada carpeta.", "",
            "| Skill | Upstream | Commit | Fecha del commit | Sincronizado | Licencia "
            "| Revisar antes de | Estado |",
            "|---|---|---|---|---|---|---|---|"]
    for i in rows("vendor"):
        repo = i.origin.replace("https://github.com/", "")
        out.append(f"| [`{i.name}`]({i.path}/SKILL.md) | [{repo}]({i.origin}) | `{i.extra['commit']}` "
                   f"| {i.updated} | {i.added} | {i.license} | {i.review_by} "
                   f"| {freshness(i.review_by, today)} |")
    out += ["", "## Skills de terceros por submódulo (`external/`)", "",
            "Siguen la rama upstream: `git submodule update --remote` (o el PR mensual de "
            "Dependabot) los trae al día. Clona con `--recurse-submodules`.", "",
            "| Skill | Upstream | Rama | Commit fijado | Fecha del commit | Licencia "
            "| Revisar antes de | Estado |",
            "|---|---|---|---|---|---|---|---|"]
    for i in rows("external"):
        repo = i.origin.replace("https://github.com/", "")
        out.append(f"| [`{i.name}`]({i.path}/SKILL.md) | [{repo}]({i.origin}) | {i.extra['branch']} "
                   f"| `{i.extra['commit']}` | {i.updated} | {i.license} | {i.review_by} "
                   f"| {freshness(i.review_by, today)} |")
    out += ["", "## Paquetes de la comunidad (`catalog/community.yaml`)", "",
            "| Paquete | Versión / commit | Fecha upstream | Verificado | Licencia "
            "| Recomendados | Integración | Revisar antes de | Estado |",
            "|---|---|---|---|---|---|---|---|---|"]
    for i in rows("community"):
        ver = i.extra["version"] if i.extra["version"] not in ("", "n/a") else ""
        vc = f"{ver} · `{i.extra['commit']}`" if ver else f"`{i.extra['commit']}`"
        rec = ", ".join(i.extra["recommended"]) or "—"
        if i.extra["submodule"]:
            ven = f"submódulo `{i.extra['submodule']}`"
        elif i.extra["vendored"]:
            ven = "vendor/: " + ", ".join(i.extra["vendored"])
        else:
            ven = "solo enlace"
        out.append(f"| [{i.path}](https://github.com/{i.path}) | {vc} | {i.updated} "
                   f"| {i.extra['verified']} | {i.license} | {rec} | {ven} | {i.review_by} "
                   f"| {freshness(i.review_by, today)} |")
    out += ["", "## Subagentes de Claude Code (`adapters/claude-code/agents/`)", "",
            "Fechas derivadas del historial git; revisión a los 6 meses del último cambio "
            "(dependen de alias de modelo y campos de Claude Code).", "",
            "| Agente | Modelo | Skills precargados | Agregado | Actualizado "
            "| Revisar antes de | Estado |",
            "|---|---|---|---|---|---|---|"]
    for i in rows("agent"):
        skills = ", ".join(i.extra["skills"]) or "—"
        out.append(f"| [`{i.name}`]({i.path}) | {i.extra['model']} | {skills} | {i.added} "
                   f"| {i.updated} | {i.review_by} | {freshness(i.review_by, today)} |")
    out.append("")
    return "\n".join(out)


# --------------------------------------------------------------------------- external
def cmd_external(fail_if_behind: bool) -> int:
    mods = submodules()
    if not mods:
        print("No hay submódulos en .gitmodules.")
        return 0
    behind_any = False
    for sm in mods:
        ref = f"refs/heads/{sm['branch']}" if sm["branch"] else "HEAD"
        remote = git("ls-remote", sm["url"], ref)
        head = remote.split()[0] if remote else None
        pinned = sm["pinned"] or "?"
        if head is None:
            print(f"{sm['path']}: no se pudo consultar {sm['url']} ({ref})")
            continue
        if head == pinned:
            print(f"{sm['path']}: al día ({pinned[:7]}, {sm['branch'] or 'HEAD'})")
            continue
        behind_any = True
        count = ""
        if sm["initialized"]:
            git("fetch", "-q", "origin", sm["branch"] or "HEAD", cwd=ROOT / sm["path"])
            n = git("rev-list", "--count", f"{pinned}..{head}", cwd=ROOT / sm["path"])
            count = f", {n} commits detrás" if n else ""
        print(f"{sm['path']}: ATRASADO — fijado {pinned[:7]}, upstream {head[:7]}{count}. "
              f"Actualizar: git submodule update --remote {sm['path']}")
    return 1 if (fail_if_behind and behind_any) else 0


# --------------------------------------------------------------------------- CLI
def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    v = sub.add_parser("validate", help="valida el kit y reporta vencidos")
    v.add_argument("--fail-on-stale", action="store_true",
                   help="exit 1 si hay elementos con review-by vencido")
    c = sub.add_parser("catalog", help="genera CATALOG.md")
    e = sub.add_parser("external", help="compara submódulos con su upstream (usa red)")
    e.add_argument("--fail-if-behind", action="store_true",
                   help="exit 1 si algún submódulo va atrasado respecto a upstream")
    for p in (v, c):
        p.add_argument("--today", type=parse_date, default=dt.date.today(),
                       help="fecha de referencia (por defecto hoy)")
    args = ap.parse_args(argv)

    if args.cmd == "external":
        return cmd_external(args.fail_if_behind)

    items, rep = collect(args.today)
    if args.cmd == "catalog":
        (ROOT / "CATALOG.md").write_text(render_catalog(items, args.today), encoding="utf-8")
        print(f"CATALOG.md generado ({len(items)} elementos).")
        if rep.errors:
            print(f"Atención: {len(rep.errors)} errores de validación; corre 'validate'.")
        return 0

    for title, lines in (("ERRORES", rep.errors), ("AVISOS", rep.warnings),
                         ("VENCIDOS (review-by pasado)", rep.stale),
                         (f"VENCEN EN ≤{SOON_DAYS} DÍAS", rep.soon)):
        if lines:
            print(f"\n{title} ({len(lines)})")
            for line in lines:
                print(f"  - {line}")
    counts = {k: sum(1 for i in items if i.kind == k)
              for k in ("own", "standalone", "vendor", "external", "community", "agent")}
    print(f"\nRevisados: {counts}. Errores: {len(rep.errors)}, avisos: {len(rep.warnings)}, "
          f"vencidos: {len(rep.stale)}.")
    if rep.errors or (args.fail_on_stale and rep.stale):
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
