# 📁 Organização do Projeto - Vinci Dentista

## 📊 Estrutura de Pastas

```
D:\VINCE DENTISTA
│
├── 📱 aplicativo_cliente/      # App móvel/cliente
├── 🖥️  src/                    # Dashboard/Backend
├── 🔧 public/                  # Assets públicos
│
├── 📚 docs/                    # 📄 DOCUMENTAÇÕES
│   ├── api/                   # Documentação de APIs
│   ├── setup/                 # Guias de instalação/configuração
│   ├── n8n/                   # Integração N8N/WhatsApp
│   ├── troubleshooting/       # Resolução de problemas
│   ├── security/              # Segurança e auditoria
│   └── legacy/                # Documentos históricos
│
└── 🗄️  sql/                    # 🔧 SCRIPTS SQL
    ├── migrations/            # Migrações de schema
    ├── fixes/                 # Scripts de correção
    ├── debug/                 # Scripts de debug/teste
    └── setup/                 # Setup inicial do BD
```

---

## 📚 Documentações

### 📡 API (`docs/api/`)
- `API_DOCUMENTATION.md` - Documentação completa da API REST
- `API-BARBEIRO-AGENDAMENTOS.md` - API específica para barbeiros
- `APIS-WHATSAPP-BARBEIROS.md` - Integração WhatsApp
- `DOCUMENTACAO-API.md` - Docs gerais

### ⚙️ Setup e Configuração (`docs/setup/`)
- `DEPLOY-VERCEL.md` - Como fazer deploy na Vercel
- `INSTRUCOES-IMPLEMENTACAO.md` - Instruções completas de implementação
- `INSTRUCOES-CONFIGURACAO-FOTO-BARBEIRO.md` - Configurar upload de fotos
- `INSTRUCOES-MOVIMENTOS-FINANCEIROS.md` - Configurar sistema financeiro
- `SETUP-REDIS-RAPIDO.md` - Setup rápido do Redis
- `COMO-CONFIGURAR-WEBHOOK-PROFISSIONAL.md` - Webhooks por barbeiro

### 🤖 N8N / WhatsApp (`docs/n8n/`)
- `GUIA-COMPLETO-N8N.md` - Guia completo de integração
- `INTEGRACAO-N8N.md` - Setup básico N8N
- `N8N-*.md` - Diversos fluxos e configurações N8N
- `PROMPT-*.md` - Prompts para agentes IA

### 🔧 Troubleshooting (`docs/troubleshooting/`)
- `RESOLVER-ERRO-FOTO-BARBEIRO.md` - Erro de upload de fotos
- `RESOLVER-ERRO-SERVICOS.md` - Problemas com serviços
- `TROUBLESHOOTING-WEBHOOK-CANCELAMENTO.md` - Debug de webhooks
- `TESTE-*.md` - Guias de teste

### 🔒 Segurança (`docs/security/`)
- `RELATORIO-SEGURANCA.md` - Auditoria completa de segurança
- `INTEGRACAO-REDIS-HISTORICO.md` - Segurança do Redis

### 📦 Legacy (`docs/legacy/`)
Documentos históricos e correções antigas. Mantidos para referência.

---

## 🗄️ Scripts SQL

### 🔄 Migrações (`sql/migrations/`)
- `SCHEMA-COMPLETO-NOVA-INSTALACAO.sql` - Schema completo para nova instalação
- `migration-foto-profissional.sql` - Adiciona campo foto_url

### 🔧 Correções (`sql/fixes/`)
- `CORRIGIR-RLS-SUPABASE.sql` - Corrige políticas RLS
- `CORRIGIR-UPLOAD-FOTOS-STORAGE.sql` - Corrige upload de fotos
- `CORRIGIR-TRIGGER-*.sql` - Correções de triggers
- `CORRIGIR-COLUNA-DATA.sql` - Correção de formato de data
- `CORRIGIR-MOVIMENTOS.sql` - Correção de movimentos financeiros

### 🐛 Debug e Testes (`sql/debug/`)
- `DEBUG-VIEWS-TRIGGERS.sql` - Debug de views e triggers
- `DIAGNOSTICO-WEBHOOK.sql` - Diagnóstico de webhooks
- `VERIFICAR-*.sql` - Scripts de verificação
- `LIMPAR-DADOS-TESTE.sql` - Limpar dados de teste
- `TENTAR-RECUPERAR-CLIENTES.sql` - Recuperar dados de clientes

---

## 🚀 Quick Start

### Para Desenvolvedores

1. **Configurar ambiente local:**
   - Leia: `docs/setup/INSTRUCOES-IMPLEMENTACAO.md`
   - Configure: `.env.local` (use `.env.example` como base)

2. **Deploy em produção:**
   - Leia: `docs/setup/DEPLOY-VERCEL.md`

3. **Configurar N8N/WhatsApp:**
   - Leia: `docs/n8n/GUIA-COMPLETO-N8N.md`

4. **Resolver problemas:**
   - Veja: `docs/troubleshooting/`

### Para DBAs

1. **Nova instalação:**
   - Execute: `sql/migrations/SCHEMA-COMPLETO-NOVA-INSTALACAO.sql`

2. **Correções:**
   - Veja: `sql/fixes/` para scripts de correção

3. **Debug:**
   - Use: `sql/debug/` para diagnóstico

---

## 📝 Regras de Organização

### ✅ Manter na Raiz
- `README.md` - Documentação principal do projeto
- `ORGANIZACAO.md` - Este arquivo (índice de organização)
- `.env.example` - Template de variáveis de ambiente
- `.gitignore` - Arquivos ignorados pelo git
- `package.json` - Dependências do projeto

### ❌ NÃO Colocar na Raiz
- Documentações (.md) → `docs/`
- Scripts SQL (.sql) → `sql/`
- Logs de debug → `docs/legacy/`
- Arquivos temporários → deletar ou mover

---

## 🔄 Manutenção

### Quando criar nova documentação:
1. Identifique a categoria (API, Setup, N8N, etc)
2. Coloque na pasta apropriada em `docs/`
3. Use nomenclatura clara: `ACAO-OBJETO.md`
4. Atualize este arquivo se criar nova categoria

### Quando criar novo script SQL:
1. Identifique o tipo (migração, correção, debug)
2. Coloque na pasta apropriada em `sql/`
3. Use prefixo claro: `ACAO-*.sql`
4. Documente o que faz no cabeçalho do arquivo

---

## 📊 Estatísticas

- **Documentações:** ~40 arquivos organizados
- **Scripts SQL:** ~18 arquivos organizados
- **Estrutura:** 10 categorias bem definidas
- **Organização:** ✅ Completa (08/01/2026)

---

**Última atualização:** 08/01/2026
**Responsável:** Claude AI
**Status:** ✅ Organizado e Limpo
