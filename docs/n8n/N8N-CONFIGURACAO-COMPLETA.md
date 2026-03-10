# 🔧 Configuração Completa do N8N - Vinci Dentista

## 📋 ÍNDICE

1. [Visão Geral](#visão-geral)
2. [Estrutura do Workflow](#estrutura-do-workflow)
3. [Configuração dos Nós](#configuração-dos-nós)
4. [Sistema de Barbeiros Automático](#sistema-de-barbeiros-automático)
5. [HTTP Requests - APIs](#http-requests---apis)
6. [Prompts dos Agentes IA](#prompts-dos-agentes-ia)
7. [Filtros e Roteamento](#filtros-e-roteamento)
8. [Exemplos de Fluxos Completos](#exemplos-de-fluxos-completos)

---

## 🎯 VISÃO GERAL

O workflow do N8N para a Vinci Dentista é composto por:

- **1 Webhook** - Recebe mensagens do WhatsApp (Evolution API)
- **4 Agentes IA** - Secretária, Agendador, Consulta Barbeiro, Cancelamento
- **5 APIs REST** - Comunicação com o sistema Next.js
- **Sistema Automático** - Detecta barbeiros pelo telefone (sem precisar criar agente para cada um)

### 🔑 URLs Base

**Desenvolvimento:**
```
http://localhost:3002
```

**Produção:**
```
https://vincedentista.com.br
```

---

## 🏗️ ESTRUTURA DO WORKFLOW

```
┌─────────────────────────────────────────────────────────────┐
│                    WEBHOOK (Evolution API)                   │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│              Extrair Variáveis (telefone, texto)             │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│           FILTRO: É barbeiro ou cliente?                     │
└───────┬───────────────────────────────────┬─────────────────┘
        │ BARBEIRO                          │ CLIENTE
        ▼                                   ▼
┌──────────────────┐              ┌──────────────────────────┐
│ Portal Barbeiro  │              │ Atendimento Cliente      │
│ (HOJE/SEMANA/    │              │ (Agendamento/Cancelar)   │
│  FATURAMENTO)    │              │                          │
└──────────────────┘              └──────────────────────────┘
```

---

## ⚙️ CONFIGURAÇÃO DOS NÓS

### 1️⃣ **Webhook Evolution API**

**Nome do nó:** `Webhook Evt`

**Configuração:**
- **HTTP Method:** POST
- **Path:** `/webhook/evolution`
- **Authentication:** None (use IP whitelist na Evolution API)
- **Response:** Return Response When Last Node Finishes

**Testar:**
```bash
curl -X POST http://localhost:5678/webhook/evolution \
  -H "Content-Type: application/json" \
  -d '{
    "key": {
      "remoteJid": "5511999999999@s.whatsapp.net"
    },
    "message": {
      "conversation": "Olá"
    }
  }'
```

---

### 2️⃣ **Extrair Variáveis**

**Nome do nó:** `Extract Variables`

**Tipo:** Code Node

**Código:**
```javascript
// Extrai telefone e mensagem do webhook
const data = $input.item.json

// Telefone (remove @s.whatsapp.net)
const telefone = data.key?.remoteJid?.replace('@s.whatsapp.net', '') || ''

// Texto da mensagem (suporta diferentes tipos)
let texto = ''
if (data.message?.conversation) {
  texto = data.message.conversation
} else if (data.message?.extendedTextMessage?.text) {
  texto = data.message.extendedTextMessage.text
} else if (data.message?.imageMessage?.caption) {
  texto = data.message.imageMessage.caption
}

// Tipo de mensagem
const tipoMensagem = data.message?.messageType || 'text'

// Nome do contato (se disponível)
const nomeContato = data.pushName || 'Cliente'

return {
  json: {
    telefone: telefone,
    texto: texto.trim(),
    tipoMensagem: tipoMensagem,
    nomeContato: nomeContato,
    dataHora: new Date().toISOString(),
    dadosOriginais: data
  }
}
```

**Output esperado:**
```json
{
  "telefone": "5511999999999",
  "texto": "Quero agendar",
  "tipoMensagem": "text",
  "nomeContato": "João Silva",
  "dataHora": "2025-12-08T14:30:00.000Z"
}
```

---

### 3️⃣ **FILTRO: Barbeiro ou Cliente?**

**Nome do nó:** `Filtro Tipo Usuario`

**Tipo:** Switch Node

**Configuração:**

```javascript
// Mode: Rules
// Data Type: String

// Regra 1: É Barbeiro?
// Campo: {{ $json.telefone }}
// Operation: is in array
// Value:

// HTTP Request para buscar barbeiros
// GET /api/barbeiros/listar
// Extrai lista de telefones dos barbeiros
```

**⚠️ IMPORTANTE:** Este filtro é **AUTOMÁTICO**!

**Implementação correta:**

1. **Adicione um nó HTTP Request antes do Switch:**

**Nome:** `Buscar Lista Barbeiros`
- **Method:** GET
- **URL:** `https://vincedentista.com.br/api/barbeiros/listar`
- **Authentication:** None

2. **Code Node para processar:**

**Nome:** `Verificar Se É Barbeiro`

```javascript
// Lista de barbeiros vinda da API
const barbeiros = $('Buscar Lista Barbeiros').item.json.barbeiros || []

// Telefone atual
const telefoneAtual = $json.telefone

// Verifica se está na lista
const ehBarbeiro = barbeiros.some(b =>
  b.telefone === telefoneAtual ||
  b.telefone === `55${telefoneAtual}` || // Com DDI
  b.telefone === telefoneAtual.replace('55', '') // Sem DDI
)

return {
  json: {
    ...($json),
    ehBarbeiro: ehBarbeiro,
    tipoConta: ehBarbeiro ? 'barbeiro' : 'cliente'
  }
}
```

3. **Switch Node:**

**Nome:** `Rotear Por Tipo`

- **Mode:** Rules
- **Regra 1:** `{{ $json.ehBarbeiro }}` equals `true` → Output 1 (Barbeiro)
- **Regra 2:** `{{ $json.ehBarbeiro }}` equals `false` → Output 2 (Cliente)

---

## 🤖 SISTEMA DE BARBEIROS AUTOMÁTICO

### ✅ Como Funciona:

1. **Novo barbeiro cadastrado no dashboard** → Tabela `profissionais`
2. **API `/api/barbeiros/listar` retorna todos automaticamente**
3. **N8N busca lista a cada mensagem** → Identifica pelo telefone
4. **Sem necessidade de criar novos agentes ou configurações**

### 📝 Adicionar Novo Barbeiro:

**Opção 1: Pelo Dashboard**
1. Acesse: `https://vincedentista.com.br/dashboard/profissionais`
2. Clique em "Novo Profissional"
3. Preencha:
   - Nome: "Carlos"
   - Telefone: "5511777777777" (com DDI)
   - Email: "carlos@vinci.com"
   - Especialidade: "Cortes clássicos"
   - Ativo: ✅

**Opção 2: Direto no Supabase**
```sql
INSERT INTO profissionais (nome, telefone, email, especialidade, ativo)
VALUES ('Carlos', '5511777777777', 'carlos@vinci.com', 'Cortes clássicos', true);
```

**Pronto!** O N8N já vai reconhecer automaticamente.

### 🔍 Testar Reconhecimento:

```bash
# 1. Listar barbeiros
curl https://vincedentista.com.br/api/barbeiros/listar

# 2. Enviar mensagem teste pelo WhatsApp
# Se o telefone estiver na lista, vai para "Portal Barbeiro"
# Se não estiver, vai para "Atendimento Cliente"
```

---

## 🌐 HTTP REQUESTS - APIS

### API 1: Listar Barbeiros

**Nome do nó:** `API - Listar Barbeiros`

**Configuração:**
- **Method:** GET
- **URL:** `https://vincedentista.com.br/api/barbeiros/listar`
- **Authentication:** None
- **Options:**
  - Response Format: JSON
  - Timeout: 10000

**Quando usar:**
- No início do workflow (para filtro)
- No agente "Agendador" (para mostrar opções)

**Response:**
```json
{
  "total": 4,
  "proximo_rodizio": {
    "id": "uuid-hiago",
    "nome": "Hiago",
    "atendimentos_hoje": 2
  },
  "barbeiros": [
    {
      "id": "uuid-hiago",
      "nome": "Hiago",
      "telefone": "5511999999999",
      "especialidade": "Cortes modernos",
      "estatisticas": {
        "total_atendimentos": 156,
        "atendimentos_hoje": 2
      }
    }
  ]
}
```

---

### API 2: Agendamentos de Hoje (Barbeiro)

**Nome do nó:** `API - Agendamentos Hoje`

**Configuração:**
- **Method:** GET
- **URL:** `https://vincedentista.com.br/api/barbeiros/agendamentos-hoje`
- **Query Parameters:**
  - `telefone`: `{{ $json.telefone }}`

**Quando usar:**
- Quando barbeiro enviar "HOJE"

**Response:**
```json
{
  "barbeiro": {
    "nome": "Hiago"
  },
  "data": "08/12/2025",
  "resumo": {
    "total_agendamentos": 3,
    "faturamento_total": 160.00,
    "proximos": 2,
    "concluidos": 1
  },
  "agendamentos": {
    "proximos": [
      {
        "hora_inicio": "14:00",
        "cliente": "Maria Costa",
        "servicos": [{"nome": "Barba", "preco": 40}],
        "valor_total": 40.00
      }
    ]
  }
}
```

---

### API 3: Agendamentos da Semana (Barbeiro)

**Nome do nó:** `API - Agendamentos Semana`

**Configuração:**
- **Method:** GET
- **URL:** `https://vincedentista.com.br/api/barbeiros/agendamentos-semana`
- **Query Parameters:**
  - `telefone`: `{{ $json.telefone }}`

**Response:**
```json
{
  "barbeiro": {
    "nome": "Hiago"
  },
  "periodo": {
    "inicio": "08/12/2025",
    "fim": "14/12/2025"
  },
  "resumo": {
    "total_agendamentos": 12,
    "faturamento_total": 980.00
  },
  "resumo_por_dia": [
    {
      "dia": "Segunda",
      "data": "09/12/2025",
      "total_agendamentos": 3,
      "faturamento": 180.00
    }
  ]
}
```

---

### API 4: Faturamento do Mês (Barbeiro)

**Nome do nó:** `API - Faturamento Mes`

**Configuração:**
- **Method:** GET
- **URL:** `https://vincedentista.com.br/api/barbeiros/faturamento-mes`
- **Query Parameters:**
  - `telefone`: `{{ $json.telefone }}`

**Response:**
```json
{
  "barbeiro": {
    "nome": "Hiago"
  },
  "periodo": {
    "mes": 12,
    "ano": 2025,
    "nome_mes": "Dezembro"
  },
  "faturamento": {
    "bruto": 4500.00,
    "confirmado": 4200.00,
    "perdido": 300.00
  },
  "estatisticas": {
    "total_agendamentos": 65,
    "compareceram": 61,
    "faltaram": 4,
    "taxa_comparecimento": "93.8%"
  },
  "top_servicos": [
    {
      "nome": "Corte",
      "quantidade": 45,
      "total": 2250.00
    }
  ]
}
```

---

### API 5: Horários Disponíveis

**Nome do nó:** `API - Horarios Disponiveis`

**Configuração:**
- **Method:** GET
- **URL:** `https://vincedentista.com.br/api/agendamentos/horarios-disponiveis`
- **Query Parameters:**
  - `data`: `{{ $json.data_escolhida }}` (formato: YYYY-MM-DD)
  - `servico_ids`: `{{ $json.servico_ids }}` (formato: uuid1,uuid2)
  - `barbeiro_id`: `{{ $json.barbeiro_id }}` (opcional)

**Quando usar:**
- No agente "Agendador", após cliente escolher serviços

**Response:**
```json
{
  "data": "2025-12-20",
  "horarios_disponiveis": [
    "09:00",
    "09:30",
    "10:00",
    "14:00",
    "15:00"
  ],
  "duracao_total": 60
}
```

---

### API 6: Criar Agendamento

**Nome do nó:** `API - Criar Agendamento`

**Configuração:**
- **Method:** POST
- **URL:** `https://vincedentista.com.br/api/agendamentos/criar`
- **Body Type:** JSON
- **Body:**
```json
{
  "cliente_nome": "{{ $json.nome_cliente }}",
  "telefone": "{{ $json.telefone }}",
  "data": "{{ $json.data_escolhida }}",
  "hora": "{{ $json.hora_escolhida }}",
  "servico_ids": "{{ $json.servico_ids }}",
  "barbeiro_preferido": "{{ $json.barbeiro_id }}"
}
```

**Response:**
```json
{
  "success": true,
  "agendamento": {
    "id": "uuid-agendamento",
    "data_agendamento": "20/12/2025",
    "hora_inicio": "14:00",
    "profissional": {
      "nome": "Hiago"
    },
    "valor_total": 70.00
  },
  "notificacao_enviada": true
}
```

---

### API 7: Meus Agendamentos (Cliente)

**Nome do nó:** `API - Meus Agendamentos`

**Configuração:**
- **Method:** GET
- **URL:** `https://vincedentista.com.br/api/clientes/meus-agendamentos`
- **Query Parameters:**
  - `telefone`: `{{ $json.telefone }}`

**Quando usar:**
- Quando cliente enviar "CANCELAR"

**Response:**
```json
{
  "cliente": {
    "telefone": "5511999999999",
    "nome": "João Silva"
  },
  "total_agendamentos": 2,
  "agendamentos_futuros": [
    {
      "id": "uuid-1",
      "data": "20/12/2025",
      "hora_inicio": "14:00",
      "barbeiro": "Hiago",
      "servicos": [{"nome": "Corte"}],
      "valor_total": 50.00,
      "pode_cancelar": true,
      "tempo_restante": "3 dias"
    }
  ]
}
```

---

### API 8: Cancelar Agendamento

**Nome do nó:** `API - Cancelar Agendamento`

**Configuração:**
- **Method:** DELETE
- **URL:** `https://vincedentista.com.br/api/agendamentos/cancelar`
- **Query Parameters:**
  - `id`: `{{ $json.agendamento_id }}`
  - `telefone`: `{{ $json.telefone }}`

**Response:**
```json
{
  "success": true,
  "message": "Agendamento cancelado com sucesso",
  "agendamento": {
    "id": "uuid-1",
    "data_agendamento": "20/12/2025",
    "hora_inicio": "14:00"
  },
  "notificacao_enviada": true
}
```

---

## 🤖 PROMPTS DOS AGENTES IA

### Agente 1: Secretária (Roteador)

**Nome do nó:** `Agente - Secretaria`

**Tipo:** AI Agent

**Model:** OpenAI GPT-4 ou GPT-3.5-turbo

**System Prompt:**
```
Você é a secretária virtual da Vinci Dentista.

Seu papel é receber o cliente, entender a intenção dele e direcionar para o agente correto.

REGRAS:
1. Seja educada, simpática e profissional
2. Cumprimente o cliente pelo nome se souber
3. Identifique a intenção:
   - "agendar", "marcar horário", "quero cortar" → AGENDAR
   - "cancelar", "desmarcar" → CANCELAR
   - "ver meus agendamentos", "consultar" → CONSULTAR
   - Outras perguntas → RESPONDER_DIRETAMENTE

INFORMAÇÕES DA DENTISTA:
- Nome: Vinci Dentista
- Horário: Segunda a Sexta 9h-20h, Sábado 9h-18h
- Endereço: [ADICIONAR ENDEREÇO]
- Telefone: [ADICIONAR TELEFONE]
- Serviços: Corte, Barba, Corte+Barba, Penteado, Química

EXEMPLOS:

Cliente: "Olá"
Você: "Olá! Bem-vindo à Vinci Dentista! 😊 Como posso ajudar você hoje?"

Cliente: "Quero agendar"
Você: "Ótimo! Vou te ajudar a agendar seu horário. Vou transferir você para nossa agenda. Um momento!"
[Direciona para: AGENDAR]

Cliente: "Preciso cancelar"
Você: "Entendo. Vou buscar seus agendamentos para você cancelar."
[Direciona para: CANCELAR]

Cliente: "Quanto custa o corte?"
Você: "Nosso corte custa R$ 50,00. Quer agendar?"

IMPORTANTE:
- Se identificar intenção de agendar, responda "ROTA:AGENDAR"
- Se identificar intenção de cancelar, responda "ROTA:CANCELAR"
- Se identificar consulta de agendamentos, responda "ROTA:CONSULTAR"
- Caso contrário, responda naturalmente
```

**Tools disponíveis:**
- Nenhuma (apenas roteamento)

---

### Agente 2: Agendador

**Nome do nó:** `Agente - Agendador`

**Tipo:** AI Agent

**Model:** OpenAI GPT-4

**System Prompt:**
```
Você é o assistente de agendamentos da Vinci Dentista.

Seu objetivo é coletar informações e criar um agendamento completo.

FLUXO DE AGENDAMENTO:
1. Confirmar nome do cliente
2. Perguntar qual serviço deseja
3. Perguntar se tem barbeiro preferido ou quer rodízio
4. Mostrar data disponível (hoje, amanhã, ou cliente escolhe)
5. Mostrar horários disponíveis
6. Confirmar todos os dados
7. Criar agendamento

INFORMAÇÕES NECESSÁRIAS:
- ✅ Nome do cliente: {{ $json.nomeContato }}
- ✅ Telefone: {{ $json.telefone }}
- ❓ Serviços escolhidos (ID e nome)
- ❓ Barbeiro preferido (ID) ou null para rodízio
- ❓ Data (YYYY-MM-DD)
- ❓ Hora (HH:MM)

SERVIÇOS DISPONÍVEIS (buscar via tool):
Use a tool "Listar Servicos" para obter a lista atualizada.

BARBEIROS DISPONÍVEIS (buscar via tool):
Use a tool "Listar Barbeiros" para obter a lista atualizada.

EXEMPLO DE CONVERSA:

Você: "Ótimo! Vou agendar para você. Qual serviço deseja?
1️⃣ Corte - R$ 50,00 (30min)
2️⃣ Barba - R$ 40,00 (30min)
3️⃣ Corte + Barba - R$ 70,00 (60min)

Responda com o número ou nome do serviço."

Cliente: "Corte e barba"

Você: "Perfeito! Corte + Barba. Tem algum barbeiro preferido?
1️⃣ Hiago - Especialista em cortes modernos
2️⃣ Filippe - Mestre em barbas
3️⃣ Alex - Cortes clássicos

Ou envie RODIZIO para deixar o sistema escolher automaticamente o barbeiro com menos atendimentos."

Cliente: "Hiago"

Você: "Ótimo! Com o Hiago. Para qual dia?
- Hoje (08/12)
- Amanhã (09/12)
- Ou me diga a data (ex: 15/12)"

Cliente: "Amanhã"

Você: [Chama tool "Buscar Horarios"] "Horários disponíveis amanhã (09/12):
⏰ 09:00
⏰ 10:00
⏰ 14:00
⏰ 15:00

Qual horário prefere?"

Cliente: "14:00"

Você: "Perfeito! Confirma os dados?
📅 Data: 09/12/2025
🕐 Hora: 14:00
👤 Barbeiro: Hiago
✂️ Serviço: Corte + Barba
💰 Valor: R$ 70,00"

Cliente: "Sim"

Você: [Chama tool "Criar Agendamento"] "✅ Agendamento confirmado!

📅 09/12/2025 às 14:00
👤 Hiago
✂️ Corte + Barba
💰 R$ 70,00

Você receberá um lembrete 2h antes. Até lá! 😊"

REGRAS IMPORTANTES:
1. SEMPRE confirme todos os dados antes de criar
2. Use as tools para buscar informações atualizadas
3. Se houver erro na criação, explique e ofereça outro horário
4. Seja educado e profissional
5. Use emojis com moderação
```

**Tools disponíveis:**
1. `Listar Servicos` → GET /api/servicos/listar
2. `Listar Barbeiros` → GET /api/barbeiros/listar
3. `Buscar Horarios` → GET /api/agendamentos/horarios-disponiveis
4. `Criar Agendamento` → POST /api/agendamentos/criar

---

### Agente 3: Portal Barbeiro

**Nome do nó:** `Agente - Portal Barbeiro`

**Tipo:** AI Agent

**Model:** OpenAI GPT-4

**System Prompt:**
```
Você é o assistente pessoal dos barbeiros da Vinci Dentista.

COMANDOS DISPONÍVEIS:
- HOJE - Ver agendamentos de hoje
- SEMANA - Ver agendamentos da semana
- FATURAMENTO - Ver faturamento do mês

BARBEIRO ATUAL: {{ $json.nomeContato }}
TELEFONE: {{ $json.telefone }}

Quando o barbeiro enviar um comando, use a tool correspondente e formate a resposta de forma clara e profissional.

FORMATO DE RESPOSTA - HOJE:
```
📊 **Seus Agendamentos Hoje** (08/12/2025)

**Resumo:**
✅ Total: 3 agendamentos
💰 Faturamento: R$ 160,00
⏰ Próximos: 2

**Próximos Agendamentos:**
⏰ 14:00 - Maria Costa
   └ Barba | R$ 40,00

⏰ 16:00 - Pedro Santos
   └ Corte + Barba | R$ 70,00

**Concluídos:**
✅ 10:00 - João Silva
   └ Corte | R$ 50,00
```

FORMATO DE RESPOSTA - SEMANA:
```
📅 **Agendamentos da Semana** (08/12 a 14/12/2025)

**Resumo Geral:**
✅ Total: 12 agendamentos
💰 Faturamento: R$ 980,00

**Por Dia:**
Segunda (09/12): 3 agendamentos | R$ 180,00
Terça (10/12): 2 agendamentos | R$ 120,00
Quarta (11/12): 4 agendamentos | R$ 260,00
Quinta (12/12): 2 agendamentos | R$ 140,00
Sexta (13/12): 1 agendamento | R$ 50,00
Sábado (14/12): 0 agendamentos | R$ 0,00
```

FORMATO DE RESPOSTA - FATURAMENTO:
```
💰 **Faturamento de Dezembro/2025**

**Resumo Financeiro:**
💵 Faturamento Bruto: R$ 4.500,00
✅ Confirmado (compareceram): R$ 4.200,00
❌ Perdido (faltaram): R$ 300,00

**Estatísticas:**
📊 Total de Agendamentos: 65
✅ Compareceram: 61 (93.8%)
❌ Faltaram: 4 (6.2%)

**Top 5 Serviços:**
1️⃣ Corte - 45x | R$ 2.250,00
2️⃣ Barba - 30x | R$ 1.200,00
3️⃣ Corte+Barba - 20x | R$ 1.400,00
```

REGRAS:
1. Detecte o comando (HOJE/SEMANA/FATURAMENTO)
2. Chame a tool correspondente
3. Formate a resposta usando os templates acima
4. Seja objetivo e profissional
5. Use emojis para melhorar visualização
```

**Tools disponíveis:**
1. `Agendamentos Hoje` → GET /api/barbeiros/agendamentos-hoje
2. `Agendamentos Semana` → GET /api/barbeiros/agendamentos-semana
3. `Faturamento Mes` → GET /api/barbeiros/faturamento-mes

---

### Agente 4: Cancelamento

**Nome do nó:** `Agente - Cancelamento`

**Tipo:** AI Agent

**Model:** OpenAI GPT-4

**System Prompt:**
```
Você é o assistente de cancelamentos da Vinci Dentista.

CLIENTE ATUAL: {{ $json.nomeContato }}
TELEFONE: {{ $json.telefone }}

FLUXO DE CANCELAMENTO:
1. Buscar agendamentos futuros do cliente (via tool)
2. Mostrar lista numerada
3. Cliente escolhe número
4. Verificar se pode cancelar (mínimo 2h de antecedência)
5. Confirmar cancelamento
6. Executar cancelamento (via tool)

REGRAS DE CANCELAMENTO:
- ✅ Pode cancelar: Falta mais de 2h para o horário
- ❌ Não pode cancelar: Falta menos de 2h (só admin pode forçar)

EXEMPLO DE CONVERSA:

Você: [Chama tool "Buscar Agendamentos"]
"Você tem 2 agendamentos futuros:

1️⃣ **20/12/2025 às 14:00**
   👤 Barbeiro: Hiago
   ✂️ Serviço: Corte
   💰 R$ 50,00
   ⏰ Falta: 3 dias

2️⃣ **22/12/2025 às 16:00**
   👤 Barbeiro: Filippe
   ✂️ Serviço: Barba
   💰 R$ 40,00
   ⏰ Falta: 5 dias

Qual você deseja cancelar? (Responda com o número)"

Cliente: "1"

Você: "Confirma o cancelamento de:
📅 20/12/2025 às 14:00
👤 Hiago - Corte
💰 R$ 50,00

⚠️ Essa ação não pode ser desfeita."

Cliente: "Sim"

Você: [Chama tool "Cancelar"] "✅ Agendamento cancelado com sucesso!

Você pode agendar novamente quando quiser. 😊"

CASO NÃO POSSA CANCELAR:
"❌ Não é possível cancelar este agendamento.

Motivo: Falta menos de 2 horas para o horário.

Para cancelar com menos de 2h, entre em contato com a dentista:
📞 [TELEFONE]"

REGRAS:
1. SEMPRE verifique se pode cancelar antes de confirmar
2. Mostre todos os dados do agendamento antes de cancelar
3. Peça confirmação explícita
4. Se não tiver agendamentos, informe educadamente
5. Seja empático e profissional
```

**Tools disponíveis:**
1. `Buscar Agendamentos` → GET /api/clientes/meus-agendamentos
2. `Cancelar Agendamento` → DELETE /api/agendamentos/cancelar

---

## 🔀 FILTROS E ROTEAMENTO

### Filtro 1: Tipo de Usuário

**Já explicado na seção 3 acima.**

---

### Filtro 2: Comandos de Barbeiro

**Nome do nó:** `Switch - Comandos Barbeiro`

**Tipo:** Switch

**Mode:** Rules

**Regras:**

1. **Comando HOJE:**
   - Campo: `{{ $json.texto }}`
   - Operação: Equal to (case insensitive)
   - Valor: `HOJE`
   - Output: 1

2. **Comando SEMANA:**
   - Campo: `{{ $json.texto }}`
   - Operação: Equal to (case insensitive)
   - Valor: `SEMANA`
   - Output: 2

3. **Comando FATURAMENTO:**
   - Campo: `{{ $json.texto }}`
   - Operação: Equal to (case insensitive)
   - Valor: `FATURAMENTO`
   - Output: 3

4. **Outros (fallback):**
   - Output: 4 → Agente Secretária

---

### Filtro 3: Intenção do Cliente

**Nome do nó:** `Switch - Intencao Cliente`

**Tipo:** Code Node (depois Switch)

**Code:**
```javascript
// Detecta intenção da mensagem do cliente
const texto = $json.texto.toLowerCase()

let intencao = 'outros'

// Palavras-chave para agendamento
const palavrasAgendar = ['agendar', 'marcar', 'horário', 'cortar', 'fazer barba', 'agendar horário']
if (palavrasAgendar.some(p => texto.includes(p))) {
  intencao = 'agendar'
}

// Palavras-chave para cancelamento
const palavrasCancelar = ['cancelar', 'desmarcar', 'não vou', 'nao vou']
if (palavrasCancelar.some(p => texto.includes(p))) {
  intencao = 'cancelar'
}

// Palavras-chave para consulta
const palavrasConsultar = ['meus agendamentos', 'ver agendamento', 'consultar']
if (palavrasConsultar.some(p => texto.includes(p))) {
  intencao = 'consultar'
}

return {
  json: {
    ...($json),
    intencao: intencao
  }
}
```

**Switch:**

- Regra 1: `{{ $json.intencao }}` = `agendar` → Agente Agendador
- Regra 2: `{{ $json.intencao }}` = `cancelar` → Agente Cancelamento
- Regra 3: `{{ $json.intencao }}` = `consultar` → Agente Consulta
- Fallback: → Agente Secretária

---

## 📱 EXEMPLOS DE FLUXOS COMPLETOS

### Fluxo 1: Cliente Agenda Horário

```
1. Cliente: "Olá, quero agendar"
   └→ Webhook recebe
   └→ Extract Variables (telefone: 5511888888888)
   └→ Buscar Barbeiros (não está na lista)
   └→ Filtro: CLIENTE
   └→ Detecta intenção: AGENDAR
   └→ Agente Agendador

2. Bot: "Ótimo! Qual serviço?"
   └→ Chama API /api/servicos/listar
   └→ Mostra lista

3. Cliente: "Corte e barba"
   └→ Agente identifica serviços

4. Bot: "Tem barbeiro preferido?"
   └→ Chama API /api/barbeiros/listar
   └→ Mostra lista + opção RODIZIO

5. Cliente: "Hiago"
   └→ Agente salva barbeiro_id

6. Bot: "Qual dia?"

7. Cliente: "Amanhã"
   └→ Agente converte para data (2025-12-09)

8. Bot: "Horários disponíveis..."
   └→ Chama API /api/agendamentos/horarios-disponiveis
   └→ Mostra lista

9. Cliente: "14:00"
   └→ Agente confirma dados

10. Bot: "Confirma?"

11. Cliente: "Sim"
    └→ Chama API /api/agendamentos/criar
    └→ Webhook dispara notificação
    └→ Bot: "✅ Agendado!"
```

---

### Fluxo 2: Barbeiro Consulta Agendamentos

```
1. Barbeiro Hiago: "HOJE"
   └→ Webhook recebe
   └→ Extract Variables (telefone: 5511999999999)
   └→ Buscar Barbeiros (está na lista!)
   └→ Filtro: BARBEIRO
   └→ Switch Comandos: HOJE
   └→ Agente Portal Barbeiro

2. Bot:
   └→ Chama API /api/barbeiros/agendamentos-hoje?telefone=5511999999999
   └→ Formata resposta:

   "📊 Seus Agendamentos Hoje (08/12/2025)

   Resumo:
   ✅ 3 agendamentos
   💰 R$ 160,00

   Próximos:
   ⏰ 14:00 - Maria (Barba - R$ 40)
   ⏰ 16:00 - Pedro (Corte+Barba - R$ 70)"
```

---

### Fluxo 3: Cliente Cancela Agendamento

```
1. Cliente: "Preciso cancelar"
   └→ Webhook recebe
   └→ Extract Variables
   └→ Filtro: CLIENTE
   └→ Detecta intenção: CANCELAR
   └→ Agente Cancelamento

2. Bot:
   └→ Chama API /api/clientes/meus-agendamentos?telefone=5511888888888
   └→ Mostra lista:

   "Você tem 2 agendamentos:
   1️⃣ 20/12 às 14:00 - Hiago - Corte
   2️⃣ 22/12 às 16:00 - Filippe - Barba

   Qual cancelar?"

3. Cliente: "1"

4. Bot: "Confirma cancelamento de 20/12 às 14:00?"

5. Cliente: "Sim"
   └→ Verifica tempo restante (> 2h? OK)
   └→ Chama API /api/agendamentos/cancelar
   └→ Webhook dispara notificação
   └→ Bot: "✅ Cancelado!"
```

---

## ✅ CHECKLIST DE IMPLEMENTAÇÃO

### Fase 1: Configuração Base
- [ ] Criar Webhook Evolution API
- [ ] Configurar Extract Variables
- [ ] Configurar Buscar Lista Barbeiros
- [ ] Configurar Filtro Tipo Usuário

### Fase 2: HTTP Requests
- [ ] API - Listar Barbeiros
- [ ] API - Agendamentos Hoje
- [ ] API - Agendamentos Semana
- [ ] API - Faturamento Mes
- [ ] API - Horarios Disponiveis
- [ ] API - Criar Agendamento
- [ ] API - Meus Agendamentos
- [ ] API - Cancelar Agendamento

### Fase 3: Agentes IA
- [ ] Agente Secretária (com system prompt)
- [ ] Agente Agendador (com tools)
- [ ] Agente Portal Barbeiro (com tools)
- [ ] Agente Cancelamento (com tools)

### Fase 4: Filtros e Roteamento
- [ ] Switch - Comandos Barbeiro
- [ ] Switch - Intenção Cliente
- [ ] Conexões entre nós

### Fase 5: Testes
- [ ] Testar webhook com mensagem real
- [ ] Testar filtro de barbeiro (enviar como barbeiro)
- [ ] Testar filtro de cliente (enviar como cliente)
- [ ] Testar comando HOJE
- [ ] Testar comando SEMANA
- [ ] Testar comando FATURAMENTO
- [ ] Testar agendamento completo
- [ ] Testar cancelamento
- [ ] Testar mensagens longas (divisão)

---

## 🎯 PRÓXIMOS PASSOS

1. **Exportar workflow atual do N8N**
2. **Criar novo workflow limpo**
3. **Seguir esta documentação passo a passo**
4. **Testar cada componente individualmente**
5. **Testar fluxos completos**
6. **Ajustar prompts conforme necessário**
7. **Documentar ajustes específicos**

---

## 📞 SUPORTE

Se tiver dúvidas durante a implementação:
1. Verifique os logs do N8N
2. Teste APIs individualmente (Postman/cURL)
3. Verifique dados retornados em cada nó
4. Consulte esta documentação

**Tudo pronto para implementar! 🚀**
