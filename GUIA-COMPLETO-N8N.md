# 🤖 Guia Completo N8N - Vinci Dentista

## 📋 ÍNDICE

1. [Configuração Inicial do N8N](#1-configuração-inicial-do-n8n)
2. [Workflow Principal - Notificações de Clientes](#2-workflow-principal---notificações-de-clientes)
3. [Workflow Barbeiros - Consultas e Gestão](#3-workflow-barbeiros---consultas-e-gestão)
4. [Workflow Interativo - Cancelamento via WhatsApp](#4-workflow-interativo---cancelamento-via-whatsapp)
5. [Endpoints da API](#5-endpoints-da-api)
6. [Exemplos de Mensagens](#6-exemplos-de-mensagens)
7. [Troubleshooting](#7-troubleshooting)

---

## 1. Configuração Inicial do N8N

### 1.1 Instalar N8N

**Opção 1: Docker (Recomendado)**
```bash
docker run -it --rm \
  --name n8n \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n
```

**Opção 2: NPM**
```bash
npm install n8n -g
n8n start
```

**Opção 3: Cloud**
- Acesse: https://n8n.io/cloud
- Crie uma conta gratuita

### 1.2 Acessar Interface
```
http://localhost:5678
```

### 1.3 Instalar Evolution API (WhatsApp)

**Docker Compose:**
```yaml
version: '3.8'
services:
  evolution-api:
    image: atendai/evolution-api:latest
    ports:
      - "8080:8080"
    environment:
      - SERVER_URL=http://localhost:8080
      - AUTHENTICATION_API_KEY=SUA_CHAVE_SECRETA_AQUI
    volumes:
      - evolution_data:/evolution/instances
      - evolution_store:/evolution/store

volumes:
  evolution_data:
  evolution_store:
```

Iniciar:
```bash
docker-compose up -d
```

### 1.4 Conectar WhatsApp

1. Acesse: http://localhost:8080
2. Crie uma instância
3. Escaneie QR Code com WhatsApp
4. Anote a **API Key** e **Instance Name**

---

## 2. Workflow Principal - Notificações de Clientes

### 2.1 Criar Novo Workflow

1. N8N → **New Workflow**
2. Nome: `Dentista - Notificações Clientes`

### 2.2 Estrutura do Workflow

```
┌─────────────┐
│   Webhook   │ ← Recebe do sistema
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Switch/IF  │ ← Filtra por tipo
└──────┬──────┘
       │
       ├─── confirmacao → WhatsApp (Confirmação)
       ├─── lembrete_24h → WhatsApp (Lembrete 24h)
       ├─── lembrete_2h → WhatsApp (Lembrete 2h)
       ├─── cancelado → WhatsApp (Cancelamento)
       ├─── followup_3d → WhatsApp (Follow-up 3d)
       └─── followup_21d → WhatsApp (Follow-up 21d)
```

### 2.3 Passo a Passo - Node por Node

#### Node 1: Webhook (Receber)

1. Adicione node **Webhook**
2. Configure:
   - **HTTP Method**: POST
   - **Path**: `dentista-notificacoes`
   - **Response Mode**: Immediately
   - **Response Code**: 200

3. **Webhook URL gerada:**
```
https://seu-n8n.com/webhook/dentista-notificacoes
```

4. **Cole essa URL no Dashboard:**
   - Configurações → Webhook de Notificações

#### Node 2: Switch (Filtro por Tipo)

1. Adicione node **Switch**
2. Configure **Mode**: Rules
3. Adicione as regras:

**Regra 1 - Confirmação:**
```javascript
{{ $json.tipo === 'confirmacao' }}
```

**Regra 2 - Lembrete 24h:**
```javascript
{{ $json.tipo === 'lembrete_24h' }}
```

**Regra 3 - Lembrete 2h:**
```javascript
{{ $json.tipo === 'lembrete_2h' }}
```

**Regra 4 - Cancelamento:**
```javascript
{{ $json.tipo === 'cancelado' }}
```

**Regra 5 - Follow-up 3 dias:**
```javascript
{{ $json.tipo === 'followup_3d' }}
```

**Regra 6 - Follow-up 21 dias:**
```javascript
{{ $json.tipo === 'followup_21d' }}
```

#### Node 3: HTTP Request (Evolution API) - Para CADA rota

**Para rota "confirmacao":**

1. Adicione node **HTTP Request**
2. Conecte na saída `0` do Switch
3. Configure:

```yaml
Method: POST
URL: http://localhost:8080/message/sendText/SUA_INSTANCIA
Authentication: Header Auth
  Header Name: apikey
  Header Value: SUA_API_KEY_EVOLUTION

Body Parameters:
{
  "number": "{{ $json.cliente.telefone }}",
  "text": "Olá {{ $json.cliente.nome }}! 👋\n\n✅ *Seu agendamento foi confirmado!*\n\n📅 *Data:* {{ $json.agendamento.data }}\n⏰ *Horário:* {{ $json.agendamento.hora }}\n💈 *Barbeiro:* {{ $json.agendamento.barbeiro }}\n💰 *Valor:* R$ {{ $json.agendamento.valor_total }}\n\n📍 *Vinci Dentista*\nNos vemos em breve! 😊"
}
```

**Para rota "lembrete_24h":**

```yaml
Body Parameters:
{
  "number": "{{ $json.cliente.telefone }}",
  "text": "Oi {{ $json.cliente.nome }}! 👋\n\n⏰ *Lembrete: Amanhã é seu dia!*\n\n📅 {{ $json.agendamento.data }}\n⏰ {{ $json.agendamento.hora }}\n💈 Com {{ $json.agendamento.barbeiro }}\n\nEstamos te esperando! 😊\n\n📍 *Vinci Dentista*"
}
```

**Para rota "lembrete_2h":**

```yaml
Body Parameters:
{
  "number": "{{ $json.cliente.telefone }}",
  "text": "🔔 *Atenção {{ $json.cliente.nome }}!*\n\nDaqui a *2 horas* é seu horário:\n\n⏰ {{ $json.agendamento.hora }}\n💈 {{ $json.agendamento.barbeiro }}\n\n📍 Vinci Dentista\nNão esqueça! 😊"
}
```

**Para rota "cancelado":**

```yaml
Body Parameters:
{
  "number": "{{ $json.cliente.telefone }}",
  "text": "Olá {{ $json.cliente.nome }},\n\n❌ Seu agendamento foi *cancelado*\n\n📅 Data: {{ $json.agendamento.data }}\n⏰ Horário: {{ $json.agendamento.hora }}\n\n{{ $json.motivo ? 'Motivo: ' + $json.motivo : '' }}\n\nPara reagendar, entre em contato conosco! 📲\n\n*Vinci Dentista*"
}
```

**Para rota "followup_3d":**

```yaml
Body Parameters:
{
  "number": "{{ $json.cliente.telefone }}",
  "text": "Olá {{ $json.cliente.nome }}! 👋\n\nComo foi seu atendimento com {{ $json.agendamento.barbeiro }}?\n\nSua opinião é muito importante! ⭐\n\nResponda:\n1️⃣ - Excelente\n2️⃣ - Bom\n3️⃣ - Regular\n4️⃣ - Ruim\n\n*Vinci Dentista*"
}
```

**Para rota "followup_21d":**

```yaml
Body Parameters:
{
  "number": "{{ $json.cliente.telefone }}",
  "text": "E aí {{ $json.cliente.nome }}! 😊\n\nJá faz um tempinho né?\n\n✂️ Que tal agendar um novo corte?\n\nTemos horários disponíveis essa semana!\n\nResponda *SIM* para ver os horários.\n\n*Vinci Dentista*"
}
```

### 2.4 Ativar Workflow

1. Clique em **Save**
2. Toggle **Active** = ON
3. Copie a URL do webhook
4. Cole no dashboard em **Configurações**

---

## 3. Workflow Barbeiros - Consultas e Gestão

### 3.1 Criar Workflow Separado

1. N8N → **New Workflow**
2. Nome: `Dentista - Portal Barbeiro`

### 3.2 Estrutura do Workflow

```
┌──────────────────┐
│ Webhook WhatsApp │ ← Mensagem do barbeiro
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  IF: É Barbeiro? │ ← Verifica se número está cadastrado
└────────┬─────────┘
         │
         ▼ SIM
┌──────────────────┐
│ Switch: Comando  │ ← Identifica o que ele quer
└────────┬─────────┘
         │
         ├─── "HOJE" → Busca agendamentos do dia → Envia WhatsApp
         ├─── "SEMANA" → Busca agendamentos da semana → Envia WhatsApp
         ├─── "FATURAMENTO" → Calcula total → Envia WhatsApp
         └─── Outro → Menu de ajuda
```

### 3.3 Passo a Passo

#### Node 1: Webhook (Evolution API)

**IMPORTANTE:** Configure webhook na Evolution API primeiro:

1. Acesse Evolution API: http://localhost:8080
2. Vá em **Webhooks**
3. Configure:
```json
{
  "url": "https://seu-n8n.com/webhook/barbeiro-whatsapp",
  "events": ["messages.upsert"],
  "webhook_by_events": true
}
```

No N8N:

1. Adicione node **Webhook**
2. Configure:
   - **Path**: `barbeiro-whatsapp`
   - **Method**: POST

#### Node 2: IF - Verificar se é Barbeiro

1. Adicione node **IF**
2. Configure **Conditions**:

```javascript
// Verifica se o número que enviou está na lista de barbeiros
{{ ["5511999999999", "5511888888888", "5511777777777"].includes($json.key.remoteJid.replace('@s.whatsapp.net', '')) }}
```

**IMPORTANTE:** Substitua pelos telefones REAIS dos barbeiros

#### Node 3: Code - Extrair Comando

Conecte na saída `true` do IF

```javascript
// Pega o texto da mensagem
const texto = $input.item.json.message?.conversation ||
              $input.item.json.message?.extendedTextMessage?.text || '';

// Pega o número do barbeiro
const telefone = $input.item.json.key.remoteJid.replace('@s.whatsapp.net', '');

// Identifica comando
const comando = texto.toUpperCase().trim();

return {
  json: {
    telefone: telefone,
    comando: comando,
    textoOriginal: texto
  }
};
```

#### Node 4: Switch - Roteamento de Comandos

1. Adicione node **Switch**
2. Configure regras:

**Regra 1 - Agendamentos de Hoje:**
```javascript
{{ $json.comando === 'HOJE' || $json.comando === 'HOJ' }}
```

**Regra 2 - Agendamentos da Semana:**
```javascript
{{ $json.comando === 'SEMANA' || $json.comando === 'SEM' }}
```

**Regra 3 - Faturamento:**
```javascript
{{ $json.comando.includes('FATURAMENTO') || $json.comando.includes('FATUR') }}
```

#### Node 5A: HTTP Request - Buscar Agendamentos HOJE

Conecte na saída `0` (HOJE) do Switch:

```yaml
Method: GET
URL: http://seu-dominio.com/api/barbeiros/agendamentos-hoje?telefone={{ $json.telefone }}
```

**Endpoint que você precisa criar:** `/api/barbeiros/agendamentos-hoje/route.ts`

```typescript
import { NextRequest, NextResponse } from 'next/server'
import { supabase } from '@/lib/supabase'

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url)
  const telefone = searchParams.get('telefone')

  if (!telefone) {
    return NextResponse.json({ success: false, message: 'Telefone não fornecido' }, { status: 400 })
  }

  // Buscar profissional pelo telefone
  const { data: profissional } = await supabase
    .from('profissionais')
    .select('id, nome')
    .eq('telefone', telefone)
    .single()

  if (!profissional) {
    return NextResponse.json({ success: false, message: 'Barbeiro não encontrado' }, { status: 404 })
  }

  // Data de hoje em formato DD/MM/YYYY
  const hoje = new Date()
  const dia = String(hoje.getDate()).padStart(2, '0')
  const mes = String(hoje.getMonth() + 1).padStart(2, '0')
  const ano = hoje.getFullYear()
  const dataHoje = `${dia}/${mes}/${ano}`

  // Buscar agendamentos de hoje
  const { data: agendamentos, error } = await supabase
    .from('agendamentos')
    .select(`
      id,
      hora_inicio,
      nome_cliente,
      telefone,
      valor,
      status,
      agendamento_servicos (
        servicos (nome, preco, duracao_minutos)
      )
    `)
    .eq('profissional_id', profissional.id)
    .eq('data_agendamento', dataHoje)
    .in('status', ['agendado', 'confirmado', 'em_andamento'])
    .order('hora_inicio')

  if (error) {
    return NextResponse.json({ success: false, message: error.message }, { status: 500 })
  }

  // Calcular totais
  const totalAgendamentos = agendamentos?.length || 0
  const faturamentoTotal = agendamentos?.reduce((sum, ag) => sum + ag.valor, 0) || 0

  return NextResponse.json({
    success: true,
    data: {
      barbeiro: profissional.nome,
      data: dataHoje,
      total_agendamentos: totalAgendamentos,
      faturamento_total: faturamentoTotal,
      agendamentos: agendamentos || []
    }
  })
}
```

#### Node 6A: Code - Formatar Mensagem HOJE

```javascript
const dados = $input.item.json.data;

if (!dados || dados.total_agendamentos === 0) {
  return {
    json: {
      mensagem: `📅 *Agendamentos de Hoje*\n\nVocê não tem agendamentos para hoje! 😊\n\nAproveite para descansar ou fazer aquele corte pessoal! ✂️`
    }
  };
}

let mensagem = `📅 *Agendamentos de Hoje* - ${dados.data}\n`;
mensagem += `👤 *Barbeiro:* ${dados.barbeiro}\n\n`;
mensagem += `📊 *Resumo:*\n`;
mensagem += `• ${dados.total_agendamentos} agendamento(s)\n`;
mensagem += `• R$ ${dados.faturamento_total.toFixed(2)} em faturamento\n\n`;
mensagem += `━━━━━━━━━━━━━━━━\n\n`;

dados.agendamentos.forEach((ag, index) => {
  mensagem += `🕐 *${ag.hora_inicio}* - ${ag.nome_cliente}\n`;
  mensagem += `   Status: ${ag.status}\n`;
  mensagem += `   Valor: R$ ${ag.valor.toFixed(2)}\n`;
  if (ag.agendamento_servicos && ag.agendamento_servicos.length > 0) {
    const servicos = ag.agendamento_servicos.map(s => s.servicos.nome).join(', ');
    mensagem += `   Serviços: ${servicos}\n`;
  }
  mensagem += `\n`;
});

mensagem += `━━━━━━━━━━━━━━━━\n`;
mensagem += `\n📲 *Comandos disponíveis:*\n`;
mensagem += `• HOJE - Ver agendamentos de hoje\n`;
mensagem += `• SEMANA - Ver agendamentos da semana\n`;
mensagem += `• FATURAMENTO - Ver faturamento do mês\n`;

return {
  json: {
    telefone: $('Code').item.json.telefone,
    mensagem: mensagem
  }
};
```

#### Node 7A: HTTP Request - Enviar WhatsApp

```yaml
Method: POST
URL: http://localhost:8080/message/sendText/SUA_INSTANCIA
Headers:
  apikey: SUA_API_KEY

Body:
{
  "number": "{{ $json.telefone }}",
  "text": "{{ $json.mensagem }}"
}
```

#### Node 5B: HTTP Request - Buscar Agendamentos SEMANA

Similar ao HOJE, mas endpoint diferente:

**Endpoint:** `/api/barbeiros/agendamentos-semana/route.ts`

```typescript
// ... código similar, mas buscando range de datas da semana
const hoje = new Date()
const inicioSemana = new Date(hoje)
inicioSemana.setDate(hoje.getDate() - hoje.getDay()) // Domingo
const fimSemana = new Date(inicioSemana)
fimSemana.setDate(inicioSemana.getDate() + 6) // Sábado

// Buscar agendamentos entre inicioSemana e fimSemana
// (converter para DD/MM/YYYY e fazer query apropriada)
```

#### Node 5C: HTTP Request - Faturamento do Mês

**Endpoint:** `/api/barbeiros/faturamento-mes/route.ts`

```typescript
// Buscar todos agendamentos do mês atual com status 'concluido'
// Somar valores
// Retornar total
```

#### Node 8: HTTP Request - Menu de Ajuda (Fallback)

Para comandos não reconhecidos:

```yaml
Body:
{
  "number": "{{ $('Code').item.json.telefone }}",
  "text": "👋 Olá!\n\n📋 *Comandos disponíveis:*\n\n• *HOJE* - Ver seus agendamentos de hoje\n• *SEMANA* - Ver agendamentos da semana\n• *FATURAMENTO* - Ver faturamento do mês\n\nDigite um dos comandos acima! 😊\n\n*Vinci Dentista - Portal do Barbeiro*"
}
```

---

## 4. Workflow Interativo - Cancelamento via WhatsApp

### 4.1 Criar Workflow

1. N8N → **New Workflow**
2. Nome: `Dentista - Cancelamento Cliente`

### 4.2 Estrutura

```
┌──────────────────┐
│ Webhook WhatsApp │ ← Cliente envia mensagem
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  IF: Tem "CANCELAR"? │
└────────┬─────────┘
         │ SIM
         ▼
┌──────────────────┐
│ HTTP: Buscar     │ ← Busca agendamentos do cliente
│ Agendamentos     │   pelo telefone
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ IF: Tem          │
│ Agendamentos?    │
└────────┬─────────┘
         │ SIM
         ▼
┌──────────────────┐
│ HTTP: Cancelar   │ ← Chama API de cancelamento
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ WhatsApp:        │ ← Confirma cancelamento
│ Confirmação      │
└──────────────────┘
```

### 4.3 Implementação

#### Node 1: Webhook Evolution

Configure webhook na Evolution API para receber mensagens

#### Node 2: IF - Detectar "CANCELAR"

```javascript
{{ ($json.message?.conversation || $json.message?.extendedTextMessage?.text || '').toUpperCase().includes('CANCELAR') }}
```

#### Node 3: Code - Extrair Dados

```javascript
const telefone = $input.item.json.key.remoteJid.replace('@s.whatsapp.net', '');
return {
  json: {
    telefone: telefone
  }
};
```

#### Node 4: HTTP - Buscar Agendamentos do Cliente

**Endpoint:** `/api/clientes/meus-agendamentos/route.ts`

```typescript
import { NextRequest, NextResponse } from 'next/server'
import { supabase } from '@/lib/supabase'

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url)
  const telefone = searchParams.get('telefone')

  if (!telefone) {
    return NextResponse.json({ success: false }, { status: 400 })
  }

  // Buscar agendamentos futuros do cliente
  const hoje = new Date()
  const { data: agendamentos } = await supabase
    .from('agendamentos')
    .select(`
      id,
      data_agendamento,
      hora_inicio,
      profissionais (nome),
      agendamento_servicos (servicos (nome))
    `)
    .eq('telefone', telefone)
    .in('status', ['agendado', 'confirmado'])
    .order('data_agendamento')
    .order('hora_inicio')
    .limit(5)

  return NextResponse.json({
    success: true,
    data: {
      agendamentos: agendamentos || []
    }
  })
}
```

```yaml
Method: GET
URL: http://seu-dominio.com/api/clientes/meus-agendamentos?telefone={{ $json.telefone }}
```

#### Node 5: IF - Tem Agendamentos?

```javascript
{{ $json.data.agendamentos.length > 0 }}
```

#### Node 6: Code - Escolher Agendamento

Se tiver apenas 1, pega ele. Se tiver mais, pega o próximo:

```javascript
const agendamentos = $input.item.json.data.agendamentos;

if (agendamentos.length === 0) {
  return {
    json: {
      sem_agendamentos: true
    }
  };
}

// Pega o próximo agendamento
const proximo = agendamentos[0];

return {
  json: {
    agendamento_id: proximo.id,
    data: proximo.data_agendamento,
    hora: proximo.hora_inicio,
    barbeiro: proximo.profissionais?.nome || 'Não definido',
    telefone: $('Code').item.json.telefone
  }
};
```

#### Node 7: HTTP - Cancelar

```yaml
Method: DELETE
URL: http://seu-dominio.com/api/agendamentos/cancelar
Body:
{
  "agendamento_id": "{{ $json.agendamento_id }}",
  "motivo": "Cancelado pelo cliente via WhatsApp",
  "cancelado_por": "cliente",
  "forcar": false
}
```

#### Node 8: Code - Formatar Resposta

```javascript
const resultado = $input.item.json;

if (resultado.success) {
  return {
    json: {
      telefone: $('Code1').item.json.telefone,
      mensagem: `✅ *Agendamento Cancelado!*\n\n📅 Data: ${$('Code2').item.json.data}\n⏰ Horário: ${$('Code2').item.json.hora}\n💈 Barbeiro: ${$('Code2').item.json.barbeiro}\n\nSeu horário foi liberado.\n\nPara agendar novamente, entre em contato! 📲\n\n*Vinci Dentista*`
    }
  };
} else {
  return {
    json: {
      telefone: $('Code1').item.json.telefone,
      mensagem: `❌ Não foi possível cancelar.\n\n${resultado.message}\n\nEntre em contato conosco: (11) 99999-9999`
    }
  };
}
```

#### Node 9: HTTP - Enviar Confirmação

```yaml
Method: POST
URL: http://localhost:8080/message/sendText/SUA_INSTANCIA
Body:
{
  "number": "{{ $json.telefone }}",
  "text": "{{ $json.mensagem }}"
}
```

---

## 5. Endpoints da API

### 5.1 Criar Novos Endpoints

Você precisa criar estes arquivos:

```
src/app/api/
├── barbeiros/
│   ├── agendamentos-hoje/route.ts
│   ├── agendamentos-semana/route.ts
│   └── faturamento-mes/route.ts
└── clientes/
    └── meus-agendamentos/route.ts
```

### 5.2 Código Completo dos Endpoints

Vou criar os arquivos completos agora...

---

## 6. Exemplos de Mensagens

### 6.1 Cliente Recebe (Confirmação)

```
Olá João Silva! 👋

✅ Seu agendamento foi confirmado!

📅 Data: 20/12/2025
⏰ Horário: 14:00
💈 Barbeiro: Hiago
💰 Valor: R$ 95,00

📍 Vinci Dentista
Nos vemos em breve! 😊
```

### 6.2 Barbeiro Consulta

**Barbeiro envia:** `HOJE`

**Recebe:**
```
📅 Agendamentos de Hoje - 08/12/2025
👤 Barbeiro: Hiago

📊 Resumo:
• 8 agendamento(s)
• R$ 720.00 em faturamento

━━━━━━━━━━━━━━━━

🕐 09:00 - João Silva
   Status: confirmado
   Valor: R$ 95.00
   Serviços: Corte, Barba

🕐 10:30 - Pedro Santos
   Status: agendado
   Valor: R$ 70.00
   Serviços: Corte

...

━━━━━━━━━━━━━━━━

📲 Comandos disponíveis:
• HOJE - Ver agendamentos de hoje
• SEMANA - Ver agendamentos da semana
• FATURAMENTO - Ver faturamento do mês
```

### 6.3 Cliente Cancela

**Cliente envia:** `CANCELAR`

**Recebe:**
```
✅ Agendamento Cancelado!

📅 Data: 20/12/2025
⏰ Horário: 14:00
💈 Barbeiro: Hiago

Seu horário foi liberado.

Para agendar novamente, entre em contato! 📲

Vinci Dentista
```

---

## 7. Troubleshooting

### 7.1 Webhook não recebe dados

**Problema:** N8N não recebe webhook do sistema

**Solução:**
1. Verifique se URL está correta no dashboard
2. Teste manualmente:
```bash
curl -X POST https://seu-n8n.com/webhook/dentista-notificacoes \
  -H "Content-Type: application/json" \
  -d '{"tipo":"teste","cliente":{"nome":"Teste"}}'
```
3. Verifique logs do N8N

### 7.2 WhatsApp não envia

**Problema:** Mensagens não chegam no WhatsApp

**Solução:**
1. Verifique se Evolution API está online
2. Confirme que WhatsApp está conectado
3. Teste envio manual na Evolution API
4. Verifique formato do número: `5511999999999` (sem @)

### 7.3 Barbeiro não reconhecido

**Problema:** Barbeiro envia comando mas não funciona

**Solução:**
1. Verifique se telefone está na lista do IF
2. Formato correto: `5511999999999` (com DDI + DDD)
3. Confira se profissional tem telefone cadastrado no banco

---

## 📚 Resumo de URLs

**N8N:** http://localhost:5678
**Evolution API:** http://localhost:8080
**Dashboard:** http://localhost:3002

**Webhooks N8N:**
- Notificações: `https://seu-n8n.com/webhook/dentista-notificacoes`
- Barbeiro: `https://seu-n8n.com/webhook/barbeiro-whatsapp`
- Cliente Cancelamento: `https://seu-n8n.com/webhook/cliente-cancelar`

---

## ✅ Checklist Final

- [ ] N8N instalado e rodando
- [ ] Evolution API instalada
- [ ] WhatsApp conectado
- [ ] Workflow notificações criado
- [ ] Workflow barbeiro criado
- [ ] Workflow cancelamento criado
- [ ] Telefones dos barbeiros configurados
- [ ] Endpoints da API criados
- [ ] Webhook URL configurada no dashboard
- [ ] Teste de envio realizado
- [ ] Teste de consulta barbeiro realizado
- [ ] Teste de cancelamento realizado

---

**Próximo passo:** Vou criar os arquivos dos endpoints da API agora! 🚀
