# 🗄️ Scripts SQL - Vinci Dentista

Scripts SQL organizados por categoria.

---

## 📂 Estrutura

### 🔄 [migrations/](./migrations/) - Migrações de Schema
Scripts para criar e alterar a estrutura do banco de dados.

**Nova Instalação:**
- **SCHEMA-COMPLETO-NOVA-INSTALACAO.sql** - Schema completo ⭐
  - Execute este para nova instalação
  - Cria todas as tabelas, views, triggers e políticas RLS

**Migrações Específicas:**
- **migration-foto-profissional.sql** - Adiciona campo `foto_url` na tabela profissionais

---

### 🔧 [fixes/](./fixes/) - Scripts de Correção
Scripts para corrigir problemas no banco de dados.

**RLS (Row Level Security):**
- **CORRIGIR-RLS-SUPABASE.sql** - Corrige políticas RLS de todas as tabelas
- **CORRIGIR-UPLOAD-FOTOS-STORAGE.sql** - Corrige RLS do Storage (fotos)

**Triggers:**
- **CORRIGIR-TRIGGER-FINAL.sql** - Correção final de triggers
- **CORRIGIR-TRIGGERS-DATA.sql** - Corrige triggers de data/hora

**Dados:**
- **CORRIGIR-COLUNA-DATA.sql** - Corrige formato de datas
- **CORRIGIR-MOVIMENTOS.sql** - Corrige movimentos financeiros

---

### 🐛 [debug/](./debug/) - Debug e Testes
Scripts para diagnóstico e testes.

**Diagnóstico:**
- **DEBUG-VIEWS-TRIGGERS.sql** - Debug de views e triggers
- **DIAGNOSTICO-WEBHOOK.sql** - Diagnóstico de webhooks
- **debug-webhook-agora.sql** - Debug rápido de webhook

**Verificação:**
- **VERIFICAR-RLS.sql** - Verifica políticas RLS
- **VERIFICAR-SCHEMA-AGENDAMENTOS.sql** - Verifica schema de agendamentos

**Limpeza:**
- **LIMPAR-DADOS-TESTE.sql** - Remove dados de teste
- **TENTAR-RECUPERAR-CLIENTES.sql** - Tenta recuperar dados de clientes

---

## 🚀 Como Usar

### Nova Instalação

Execute na ordem:

1. **Criar Schema Completo:**
   ```sql
   -- No SQL Editor do Supabase
   \i migrations/SCHEMA-COMPLETO-NOVA-INSTALACAO.sql
   ```

2. **Aplicar Migrações (se necessário):**
   ```sql
   \i migrations/migration-foto-profissional.sql
   ```

3. **Verificar RLS:**
   ```sql
   \i debug/VERIFICAR-RLS.sql
   ```

---

### Corrigir Problemas

**Problema com RLS:**
```sql
-- Corrige políticas de todas as tabelas
\i fixes/CORRIGIR-RLS-SUPABASE.sql
```

**Problema com Upload de Fotos:**
```sql
-- Corrige bucket e políticas do Storage
\i fixes/CORRIGIR-UPLOAD-FOTOS-STORAGE.sql
```

**Problema com Triggers:**
```sql
-- Corrige triggers de data/hora
\i fixes/CORRIGIR-TRIGGERS-DATA.sql

-- Correção final
\i fixes/CORRIGIR-TRIGGER-FINAL.sql
```

**Problema com Datas:**
```sql
-- Corrige formato de datas
\i fixes/CORRIGIR-COLUNA-DATA.sql
```

---

### Debug

**Verificar Views e Triggers:**
```sql
\i debug/DEBUG-VIEWS-TRIGGERS.sql
```

**Verificar Webhooks:**
```sql
\i debug/DIAGNOSTICO-WEBHOOK.sql
```

**Verificar RLS:**
```sql
\i debug/VERIFICAR-RLS.sql
```

---

## ⚠️ Avisos Importantes

### Antes de Executar

1. ✅ **Faça backup** do banco de dados
2. ✅ **Teste em desenvolvimento** primeiro
3. ✅ **Leia o script** antes de executar
4. ✅ **Verifique permissões** no Supabase

### Scripts Destrutivos

⚠️ **CUIDADO** com estes scripts:
- `LIMPAR-DADOS-TESTE.sql` - DELETA dados
- `TENTAR-RECUPERAR-CLIENTES.sql` - Modifica dados

**SEMPRE faça backup antes!**

---

## 📝 Convenções

### Nomenclatura
- **ACAO-OBJETO.sql** - Padrão geral
- **CORRIGIR-*.sql** - Scripts de correção
- **DEBUG-*.sql** - Scripts de debug
- **VERIFICAR-*.sql** - Scripts de verificação
- **migration-*.sql** - Migrações

### Estrutura dos Scripts
```sql
-- =====================================================
-- TÍTULO DO SCRIPT
-- =====================================================
-- Descrição do que faz
-- Data: DD/MM/YYYY
-- Autor: Nome
-- =====================================================

-- Código aqui
```

---

## 🔄 Manutenção

### Criar Novo Script de Migração
1. Crie arquivo: `migrations/migration-descricao.sql`
2. Adicione cabeçalho descritivo
3. Teste em desenvolvimento
4. Documente aqui

### Criar Script de Correção
1. Crie arquivo: `fixes/CORRIGIR-PROBLEMA.sql`
2. Adicione comentários explicativos
3. Teste antes de usar em produção
4. Atualize este README

---

## 📊 Estatísticas

- **Migrações:** 2 scripts
- **Correções:** 6 scripts
- **Debug:** 10 scripts
- **Total:** 18 scripts SQL organizados

---

**Última atualização:** 08/01/2026
