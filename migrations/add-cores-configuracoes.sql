-- Migration: Adicionar colunas de cor personalizada na tabela configuracoes
-- Execute no Supabase SQL Editor

ALTER TABLE public.configuracoes
  ADD COLUMN IF NOT EXISTS cor_primaria   VARCHAR(7) DEFAULT '#1c283c',
  ADD COLUMN IF NOT EXISTS cor_secundaria VARCHAR(7) DEFAULT '#2d3f5f',
  ADD COLUMN IF NOT EXISTS cor_acento     VARCHAR(7) DEFAULT '#4a6082',
  ADD COLUMN IF NOT EXISTS cor_gold       VARCHAR(7) DEFAULT '#c8a871';
