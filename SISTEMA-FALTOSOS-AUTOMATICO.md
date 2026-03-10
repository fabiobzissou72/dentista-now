# 🚫 Sistema Automático de Marcação de Faltosos

## O Problema

Agendamentos com horário já passado ficavam com status "agendado" ou "confirmado" para sempre, mesmo quando o cliente não compareceu.

**Exemplo:**
- Agendamento: 15/01/2026 às 09:11
- Hora atual: 15/01/2026 às 11:00
- Status: **"agendado"** ❌ (deveria ser "não compareceu")

## A Solução

Sistema automático que **a cada hora** verifica agendamentos vencidos e marca como "não compareceu" automaticamente.

---

## 📋 Como Funciona

### Lógica do Sistema:

1. **A cada hora**, o sistema busca agendamentos com status:
   - `agendado`
   - `confirmado`

2. **Verifica** se a data/hora já passou (+ **30 minutos de tolerância**)

3. **Marca automaticamente** como:
   - Status: `cancelado`
   - Compareceu: `false`
   - Observações: "Cliente não compareceu - marcado automaticamente pelo sistema"

### Tolerância de 30 minutos:

**Por quê?** Para dar uma margem ao cliente que chegou com atraso.

**Exemplo:**
- Agendamento: 09:00
- Cliente chega: 09:15 (15min atrasado)
- Sistema só marca como faltoso após: **09:30**

---

## 🔧 Como Configurar

### 1. Testar Manualmente

Execute o script SQL para ver quais agendamentos seriam marcados:

```bash
# Arquivo: testar-faltosos.sql
```

Abra o SQL Editor do Supabase e execute para ver:
- Agendamentos que deveriam ser faltosos
- Estatísticas de comparecimento
- Últimos marcados como faltosos

### 2. Testar o Endpoint (Executar agora)

```bash
curl "https://vincidentista.vercel.app/api/cron/marcar-faltosos"
```

**Resposta esperada:**
```json
{
  "success": true,
  "message": "Verificação de faltosos concluída",
  "data": {
    "total_verificados": 15,
    "marcados_como_faltosos": 3,
    "erros": []
  },
  "timestamp": "2026-01-15T14:30:00.000Z"
}
```

### 3. Configurar no N8N (Automático)

Você tem **2 opções**:

#### Opção A: Adicionar ao cron de lembretes existente

Adicione uma chamada extra no workflow de lembretes:

```
Schedule (cada hora)
   ↓
HTTP Request → /api/cron/lembretes
   ↓
HTTP Request → /api/cron/marcar-faltosos
```

#### Opção B: Criar workflow separado

Crie um novo workflow só para faltosos:

**Nó 1: Schedule Trigger**
- Mode: Every Hour
- Hours: 8,9,10,11,12,13,14,15,16,17,18,19,20
- Minutes: 0

**Nó 2: HTTP Request**
- Method: GET
- URL: `https://vincidentista.vercel.app/api/cron/marcar-faltosos`

**JSON do Workflow:**
```json
{
  "name": "Cron - Marcar Faltosos",
  "nodes": [
    {
      "parameters": {
        "rule": {
          "interval": [
            {
              "field": "hours",
              "hoursInterval": 1
            }
          ]
        }
      },
      "name": "Schedule Trigger",
      "type": "n8n-nodes-base.scheduleTrigger",
      "typeVersion": 1,
      "position": [250, 300]
    },
    {
      "parameters": {
        "method": "GET",
        "url": "https://vincidentista.vercel.app/api/cron/marcar-faltosos",
        "options": {}
      },
      "name": "Marcar Faltosos",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4.1,
      "position": [470, 300]
    }
  ],
  "connections": {
    "Schedule Trigger": {
      "main": [
        [
          {
            "node": "Marcar Faltosos",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  }
}
```

---

## 📊 Verificar Resultados

### No Dashboard:

Vá em **Agendamentos** e filtre por:
- Status: `cancelado`
- Compareceu: `false`

### No Supabase:

```sql
SELECT
  nome_cliente,
  data_agendamento,
  hora_inicio,
  status,
  compareceu,
  observacoes
FROM agendamentos
WHERE compareceu = false
  AND observacoes LIKE '%marcado automaticamente%'
ORDER BY data_agendamento DESC, hora_inicio DESC
LIMIT 20;
```

---

## 🎯 Benefícios

✅ **Dados corretos** - Status reflete a realidade
✅ **Estatísticas precisas** - Taxa de comparecimento real
✅ **Automático** - Sem trabalho manual
✅ **Relatórios confiáveis** - Sabe quem falta muito
✅ **Agenda limpa** - Não fica agendamento "fantasma"

---

## ⚙️ Configurações

### Alterar tolerância (padrão: 30 minutos)

Edite o arquivo `src/app/api/cron/marcar-faltosos/route.ts`:

```typescript
// Linha 36 - Altere o valor aqui:
limiteTolerancia.setMinutes(limiteTolerancia.getMinutes() - 30)

// Para 15 minutos:
limiteTolerancia.setMinutes(limiteTolerancia.getMinutes() - 15)

// Para 1 hora:
limiteTolerancia.setMinutes(limiteTolerancia.getMinutes() - 60)
```

### Alterar status final

Por padrão marca como `cancelado`. Se preferir criar um status novo:

1. Adicione status `nao_compareceu` no banco
2. Altere linha 104:
```typescript
status: 'nao_compareceu',  // ao invés de 'cancelado'
```

---

## 🧪 Testes

### Cenário 1: Agendamento vencido

```
Agendamento: 15/01/2026 09:00
Hora atual: 15/01/2026 10:00
Resultado: ✅ Marcado como faltoso (passou + 30min)
```

### Cenário 2: Dentro da tolerância

```
Agendamento: 15/01/2026 09:00
Hora atual: 15/01/2026 09:15
Resultado: ⏳ Aguardando (ainda na tolerância de 30min)
```

### Cenário 3: Agendamento futuro

```
Agendamento: 15/01/2026 15:00
Hora atual: 15/01/2026 10:00
Resultado: ⏰ Não processa (ainda não chegou a hora)
```

---

## 🚀 Pronto!

Execute o curl agora para testar:

```bash
curl "https://vincidentista.vercel.app/api/cron/marcar-faltosos"
```

Configure no N8N e nunca mais se preocupe com agendamentos "fantasma"! 🎉
