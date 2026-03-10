-- =====================================================
-- CONFIGURAÇÃO DE RLS (Row Level Security) - SUPABASE
-- VINCI DENTISTA
-- =====================================================
--
-- Execute este script no SQL Editor do Supabase
-- para permitir que as APIs funcionem corretamente
--
-- Data: 10/12/2025
-- =====================================================

-- 1️⃣ ATIVAR RLS NAS TABELAS (se ainda não estiver ativo)
ALTER TABLE agendamentos ENABLE ROW LEVEL SECURITY;
ALTER TABLE agendamento_servicos ENABLE ROW LEVEL SECURITY;
ALTER TABLE profissionais ENABLE ROW LEVEL SECURITY;
ALTER TABLE servicos ENABLE ROW LEVEL SECURITY;
ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE configuracoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE notificacoes_enviadas ENABLE ROW LEVEL SECURITY;
ALTER TABLE agendamentos_cancelamentos ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 2️⃣ POLÍTICAS PARA TABELA: agendamentos
-- =====================================================

-- Remover políticas antigas (se existirem)
DROP POLICY IF EXISTS "agendamentos_select_all" ON agendamentos;
DROP POLICY IF EXISTS "agendamentos_insert_anon" ON agendamentos;
DROP POLICY IF EXISTS "agendamentos_update_anon" ON agendamentos;
DROP POLICY IF EXISTS "agendamentos_delete_anon" ON agendamentos;

-- Permitir SELECT (leitura) para usuários anônimos
CREATE POLICY "agendamentos_select_all" ON agendamentos
FOR SELECT
TO anon, authenticated
USING (true);

-- Permitir INSERT (criação) para usuários anônimos
CREATE POLICY "agendamentos_insert_anon" ON agendamentos
FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- Permitir UPDATE (atualização) para usuários anônimos
CREATE POLICY "agendamentos_update_anon" ON agendamentos
FOR UPDATE
TO anon, authenticated
USING (true)
WITH CHECK (true);

-- Permitir DELETE (exclusão) para usuários anônimos
CREATE POLICY "agendamentos_delete_anon" ON agendamentos
FOR DELETE
TO anon, authenticated
USING (true);

-- =====================================================
-- 3️⃣ POLÍTICAS PARA TABELA: agendamento_servicos
-- =====================================================

DROP POLICY IF EXISTS "agendamento_servicos_select_all" ON agendamento_servicos;
DROP POLICY IF EXISTS "agendamento_servicos_insert_anon" ON agendamento_servicos;
DROP POLICY IF EXISTS "agendamento_servicos_update_anon" ON agendamento_servicos;
DROP POLICY IF EXISTS "agendamento_servicos_delete_anon" ON agendamento_servicos;

CREATE POLICY "agendamento_servicos_select_all" ON agendamento_servicos
FOR SELECT
TO anon, authenticated
USING (true);

CREATE POLICY "agendamento_servicos_insert_anon" ON agendamento_servicos
FOR INSERT
TO anon, authenticated
WITH CHECK (true);

CREATE POLICY "agendamento_servicos_update_anon" ON agendamento_servicos
FOR UPDATE
TO anon, authenticated
USING (true)
WITH CHECK (true);

CREATE POLICY "agendamento_servicos_delete_anon" ON agendamento_servicos
FOR DELETE
TO anon, authenticated
USING (true);

-- =====================================================
-- 4️⃣ POLÍTICAS PARA TABELA: profissionais
-- =====================================================

DROP POLICY IF EXISTS "profissionais_select_all" ON profissionais;
DROP POLICY IF EXISTS "profissionais_insert_anon" ON profissionais;
DROP POLICY IF EXISTS "profissionais_update_anon" ON profissionais;

CREATE POLICY "profissionais_select_all" ON profissionais
FOR SELECT
TO anon, authenticated
USING (true);

-- Admin pode inserir/atualizar profissionais
CREATE POLICY "profissionais_insert_anon" ON profissionais
FOR INSERT
TO anon, authenticated
WITH CHECK (true);

CREATE POLICY "profissionais_update_anon" ON profissionais
FOR UPDATE
TO anon, authenticated
USING (true)
WITH CHECK (true);

-- =====================================================
-- 5️⃣ POLÍTICAS PARA TABELA: servicos
-- =====================================================

DROP POLICY IF EXISTS "servicos_select_all" ON servicos;
DROP POLICY IF EXISTS "servicos_insert_anon" ON servicos;
DROP POLICY IF EXISTS "servicos_update_anon" ON servicos;

CREATE POLICY "servicos_select_all" ON servicos
FOR SELECT
TO anon, authenticated
USING (true);

CREATE POLICY "servicos_insert_anon" ON servicos
FOR INSERT
TO anon, authenticated
WITH CHECK (true);

CREATE POLICY "servicos_update_anon" ON servicos
FOR UPDATE
TO anon, authenticated
USING (true)
WITH CHECK (true);

-- =====================================================
-- 6️⃣ POLÍTICAS PARA TABELA: clientes
-- =====================================================

DROP POLICY IF EXISTS "clientes_select_all" ON clientes;
DROP POLICY IF EXISTS "clientes_insert_anon" ON clientes;
DROP POLICY IF EXISTS "clientes_update_anon" ON clientes;

CREATE POLICY "clientes_select_all" ON clientes
FOR SELECT
TO anon, authenticated
USING (true);

CREATE POLICY "clientes_insert_anon" ON clientes
FOR INSERT
TO anon, authenticated
WITH CHECK (true);

CREATE POLICY "clientes_update_anon" ON clientes
FOR UPDATE
TO anon, authenticated
USING (true)
WITH CHECK (true);

-- =====================================================
-- 7️⃣ POLÍTICAS PARA TABELA: configuracoes
-- =====================================================

DROP POLICY IF EXISTS "configuracoes_select_all" ON configuracoes;
DROP POLICY IF EXISTS "configuracoes_update_anon" ON configuracoes;

CREATE POLICY "configuracoes_select_all" ON configuracoes
FOR SELECT
TO anon, authenticated
USING (true);

CREATE POLICY "configuracoes_update_anon" ON configuracoes
FOR UPDATE
TO anon, authenticated
USING (true)
WITH CHECK (true);

-- =====================================================
-- 8️⃣ POLÍTICAS PARA TABELA: notificacoes_enviadas
-- =====================================================

DROP POLICY IF EXISTS "notificacoes_select_all" ON notificacoes_enviadas;
DROP POLICY IF EXISTS "notificacoes_insert_anon" ON notificacoes_enviadas;

CREATE POLICY "notificacoes_select_all" ON notificacoes_enviadas
FOR SELECT
TO anon, authenticated
USING (true);

CREATE POLICY "notificacoes_insert_anon" ON notificacoes_enviadas
FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- =====================================================
-- 9️⃣ POLÍTICAS PARA TABELA: agendamentos_cancelamentos
-- =====================================================

DROP POLICY IF EXISTS "cancelamentos_select_all" ON agendamentos_cancelamentos;
DROP POLICY IF EXISTS "cancelamentos_insert_anon" ON agendamentos_cancelamentos;

CREATE POLICY "cancelamentos_select_all" ON agendamentos_cancelamentos
FOR SELECT
TO anon, authenticated
USING (true);

CREATE POLICY "cancelamentos_insert_anon" ON agendamentos_cancelamentos
FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- =====================================================
-- 🔟 VERIFICAR POLÍTICAS CRIADAS
-- =====================================================

SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN (
  'agendamentos',
  'agendamento_servicos',
  'profissionais',
  'servicos',
  'clientes',
  'configuracoes',
  'notificacoes_enviadas',
  'agendamentos_cancelamentos'
)
ORDER BY tablename, policyname;

-- =====================================================
-- ✅ PRONTO!
-- =====================================================
--
-- Após executar este script, suas APIs devem funcionar
-- corretamente sem erros de permissão RLS.
--
-- IMPORTANTE:
-- - Usuários anônimos (anon) podem fazer tudo
-- - Usuários autenticados (authenticated) também podem
-- - Para produção, você pode restringir mais se necessário
--
-- =====================================================
