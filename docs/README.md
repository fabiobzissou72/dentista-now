# 📚 Documentações - Vinci Dentista

Bem-vindo à central de documentações do projeto!

---

## 📂 Estrutura

### 📡 [api/](./api/) - Documentação de APIs
Documentação completa das APIs REST do sistema.

- **API_DOCUMENTATION.md** - Documentação completa da API
- **API-BARBEIRO-AGENDAMENTOS.md** - API para barbeiros
- **APIS-WHATSAPP-BARBEIROS.md** - Integração WhatsApp
- **DOCUMENTACAO-API.md** - Documentação geral

---

### ⚙️ [setup/](./setup/) - Instalação e Configuração
Guias passo a passo para configurar o sistema.

- **DEPLOY-VERCEL.md** - Deploy na Vercel ⭐
- **INSTRUCOES-IMPLEMENTACAO.md** - Implementação completa ⭐
- **SETUP-REDIS-RAPIDO.md** - Setup rápido do Redis
- **INSTRUCOES-CONFIGURACAO-FOTO-BARBEIRO.md** - Upload de fotos
- **INSTRUCOES-MOVIMENTOS-FINANCEIROS.md** - Sistema financeiro
- **COMO-CONFIGURAR-WEBHOOK-PROFISSIONAL.md** - Webhooks personalizados

---

### 🤖 [n8n/](./n8n/) - N8N e WhatsApp
Integração com N8N para automação via WhatsApp.

**Guias Principais:**
- **GUIA-COMPLETO-N8N.md** - Guia completo ⭐
- **INTEGRACAO-N8N.md** - Setup básico

**Configurações Específicas:**
- **N8N-CONFIGURACAO-COMPLETA.md** - Config completa
- **N8N-CONFIGURACAO-ZAYLA.md** - Config da Zayla (secretária)
- **N8N-SETUP-RAPIDO-NOTIFICACAO.md** - Notificações rápidas

**Fluxos:**
- **N8N-FLUXO-BARBEIRO-COMPLETO.md** - Fluxo completo
- **N8N-CANCELAR-SIMPLES.md** - Cancelamento
- **N8N-CRON-FOLLOWUP.md** - Follow-ups automáticos
- **N8N-NOTIFICAR-CLIENTE-CANCELAMENTO.md** - Notificações

**Prompts IA:**
- **PROMPT-ZAYLA-SECRETARIA-CORRIGIDO.md** - Prompt da Zayla
- **PROMPT-SETORIZADOR-CORRIGIDO.md** - Setorizador
- **PROMPT-SETORIZADOR-SIMPLIFICADO.md** - Setorizador simples

**Implementações:**
- **N8N-IMPLEMENTACAO-PRE-FILTRO.md** - Pré-filtro de mensagens

---

### 🔧 [troubleshooting/](./troubleshooting/) - Resolução de Problemas
Soluções para problemas comuns.

**Erros Comuns:**
- **RESOLVER-ERRO-FOTO-BARBEIRO.md** - Erro no upload de fotos
- **RESOLVER-ERRO-SERVICOS.md** - Problemas com serviços
- **TROUBLESHOOTING-WEBHOOK-CANCELAMENTO.md** - Debug de webhooks

**Testes:**
- **TESTE-FINAL-AGENDAMENTO.md** - Teste completo
- **TESTE-RAPIDO.md** - Teste rápido
- **TESTE-WEBHOOK-AGORA.md** - Teste de webhooks

---

### 🔒 [security/](./security/) - Segurança
Documentação de segurança e auditoria.

- **RELATORIO-SEGURANCA.md** - Auditoria completa de segurança ⭐
- **INTEGRACAO-REDIS-HISTORICO.md** - Segurança do Redis

---

### 📦 [legacy/](./legacy/) - Documentos Históricos
Documentações antigas mantidas para referência.

Inclui correções antigas, documentos de migração e histórico de desenvolvimento.

---

## 🚀 Por Onde Começar?

### Novo no Projeto?
1. Leia: `setup/INSTRUCOES-IMPLEMENTACAO.md`
2. Configure: `.env.local`
3. Execute: migrações SQL

### Fazer Deploy?
1. Leia: `setup/DEPLOY-VERCEL.md`
2. Configure: variáveis de ambiente na Vercel
3. Deploy!

### Configurar WhatsApp?
1. Leia: `n8n/GUIA-COMPLETO-N8N.md`
2. Configure: workflows N8N
3. Teste: com números reais

### Problema?
1. Veja: `troubleshooting/`
2. Procure: pelo erro específico
3. Execute: scripts de correção se necessário

---

## 📝 Convenções

### Nomenclatura
- **ACAO-OBJETO.md** - Padrão geral
- **N8N-*.md** - Documentos N8N
- **INSTRUCOES-*.md** - Guias de instruções
- **RESOLVER-*.md** - Soluções de problemas
- **TESTE-*.md** - Documentos de teste

### Emojis
- ⭐ - Documentos importantes
- 🔴 - Crítico/urgente
- 🟡 - Atenção necessária
- 🟢 - OK/estável
- ⚠️ - Aviso/cuidado

---

**Última atualização:** 08/01/2026
