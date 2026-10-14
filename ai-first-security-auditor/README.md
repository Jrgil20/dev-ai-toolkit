# AI-First Security Auditor (`ai-first-security-auditor`)

Paquete de auditoría de seguridad y remediación directa diseñado para proyectos construidos intensivamente con asistentes de IA (Cursor, GitHub Copilot, Antigravity, Claude Code) donde la seguridad, las políticas RLS y las fronteras de Clean/Hexagonal Architecture fueron relegadas durante el desarrollo rápido.

## Estructura del Paquete

```text
ai-first-security-auditor/
├── SKILL.md                           # Instrucciones principales de la Skill y Matriz CVE/CWE
├── README.md                          # Guía de despliegue multi-repositorio
├── scripts/
│   └── recon_audit.sh                 # Escáner estático en Bash (Secretos, RLS, Casts TS, CVEs)
└── references/
    └── remediation_patterns.md        # Plantillas listas para producción (Zod, Supabase RLS, Express, Docker)
```

## ¿Repositorio Git o GitHub Gist?

Dado que esta skill es multi-archivo y mantiene una jerarquía de directorios (`scripts/` y `references/`), un repositorio de GitHub dedicado es superior a un Gist (los Gists aplanan todos los archivos en un solo nivel y rompen las rutas relativas como `scripts/recon_audit.sh`).

### Opción A: Usar como Submódulo Git en múltiples proyectos (Recomendado)

1. Crea un repositorio en tu cuenta (ej. `Jrgil20/ai-first-security-auditor`) y sube el contenido de esta carpeta.
2. En cualquier proyecto que quieras auditar o blindar, inyéctala como submódulo o clónala en tu carpeta de agentes:

```bash
# Para usar en entornos de agentes / Cursor / Antigravity / Copilot
git submodule add https://github.com/<TU_USUARIO>/ai-first-security-auditor.git .agents/skills/ai-first-security-auditor
chmod +x .agents/skills/ai-first-security-auditor/scripts/recon_audit.sh
```

### Opción B: Ejecución directa del Reconocimiento Estático en Linux

Desde la raíz de cualquier repositorio TypeScript / Node.js / Expo / Supabase:

```bash
./.agents/skills/ai-first-security-auditor/scripts/recon_audit.sh .
```
