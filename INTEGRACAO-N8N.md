# 🤖 Documentação de Integração N8N - Vince Dentista

## 📋 Índice
1. [Visão Geral](#visão-geral)
2. [Configuração Inicial](#configuração-inicial)
3. [Endpoints da API](#endpoints-da-api)
4. [Webhooks do Dashboard](#webhooks-do-dashboard)
5. [Exemplos de Fluxos N8N](#exemplos-de-fluxos-n8n)
6. [Tratamento de Erros](#tratamento-de-erros)

---

## 🎯 Visão Geral

O sistema de agendamento da Vince Dentista se integra com o N8N de forma **bidirecional**:

- **N8N → Dashboard**: Criar agendamentos, confirmar comparecimento, consultar horários
- **Dashboard → N8N**: Notificações automáticas (confirmação, lembretes, follow-ups)

---

## ⚙️ Configuração Inicial

### 1. Configurar Webhook no Dashboard

Acesse o dashboard em **Configurações** e adicione a URL do webhook N8N:

```
https://seu-n8n.com/webhook/dentista
```

Ative/desative os tipos de notificação:
- ✅ Confirmação imediata
- ✅ Lembrete 24h antes
- ✅ Lembrete 2h antes
- ☐ Follow-up 3 dias (feedback)
- ☐ Follow-up 21 dias (reagendar)
- ✅ Notificar cancelamentos

### 2. Executar Script SQL no Supabase

No Supabase SQL Editor, execute o arquivo:
```sql
src/lib/rodizio-notificacoes.sql
```

Isso criará:
- Tabelas de rodízio
- Tabelas de notificações
- Triggers automáticos
- Views de consulta

### 3. Configurar Vercel Cron (Opcional)

O cron já está configurado no `vercel.json`. Para segurança, adicione no Vercel:

**Environment Variable:**
```
CRON_SECRET=seu_token_secreto_aqui
```

---

## 🔌 Endpoints da API

### Base URL
```
Produção: https://seu-dominio.vercel.app/api
Local: http://localhost:3000/api
```

---

## 📡 1. Consultar Horários Disponíveis

**Endpoint:** `GET /api/agendamentos/horarios-disponiveis`

**Descrição:** Retorna todos os horários disponíveis para um dia específico.

**Query Params:**
| Parâmetro | Tipo | Obrigatório | Descrição |
|-----------|------|-------------|-----------|
| data | string | ✅ Sim | Data no formato YYYY-MM-DD |
| barbeiro | string | ❌ Não | Nome do barbeiro (se vazio, verifica todos) |
| servico_ids | string | ❌ Não | IDs separados por vírgula para calcular duração |

**Exemplo de Requisição:**
```http
GET /api/agendamentos/horarios-disponiveis?data=2025-12-20&barbeiro=Hiago
```

**Resposta de Sucesso:**
```json
{
  "success": true,
  "message": "15 horários disponíveis encontrados",
  "data": {
    "data": "2025-12-20",
    "dia_semana": "Sexta",
    "horario_abertura": "09:00",
    "horario_fechamento": "19:00",
    "duracao_estimada": 30,
    "barbeiros_disponiveis": 3,
    "barbeiros": [
      { "id": "uuid-123", "nome": "Hiago" },
      { "id": "uuid-456", "nome": "Alex" }
    ],
    "horarios": ["09:00", "09:30", "10:00", "14:00", "15:30"],
    "total_disponiveis": 5,
    "total_ocupados": 10
  }
}
```

**Resposta de Erro (Dia Fechado):**
```json
{
  "success": false,
  "message": "Dentista fechada em Domingo",
  "data": {
    "horarios": [],
    "dia_fechado": true,
    "dia_semana": "Domingo"
  }
}
```

---

## 📅 2. Criar Agendamento

**Endpoint:** `POST /api/agendamentos/criar`

**Descrição:** Cria um novo agendamento com sistema de rodízio automático.

**Headers:**
```http
Content-Type: application/json
```

**Body:**
```json
{
  "cliente_nome": "João Silva",
  "telefone": "11999999999",
  "data": "2025-12-20",
  "hora": "14:00",
  "servico_ids": ["uuid-servico-1", "uuid-servico-2"],
  "barbeiro_preferido": "Hiago",  // Opcional
  "observacoes": "Cliente prefere corte degradê",  // Opcional
  "cliente_id": "uuid-cliente"  // Opcional (se já cadastrado)
}
```

**Resposta de Sucesso:**
```json
{
  "success": true,
  "message": "Agendamento criado com sucesso!",
  "data": {
    "agendamento_id": "uuid-agendamento",
    "barbeiro_atribuido": "Hiago",
    "data": "2025-12-20",
    "horario": "14:00",
    "valor_total": 125.00,
    "duracao_total": 60,
    "servicos": [
      { "nome": "Corte", "preco": 70.00 },
      { "nome": "Barba", "preco": 55.00 }
    ],
    "status": "agendado"
  }
}
```

**Resposta de Erro (Horário Ocupado):**
```json
{
  "success": false,
  "message": "Horário 14:00 já está ocupado para Hiago",
  "errors": ["Conflito de horário"],
  "data": {
    "barbeiro": "Hiago",
    "horario_solicitado": "14:00",
    "sugestoes": ["14:30", "15:00", "15:30", "16:00"]
  }
}
```

### Sistema de Rodízio

**Se `barbeiro_preferido` NÃO for informado:**
- Sistema seleciona automaticamente o barbeiro com **menos agendamentos do dia**
- Critério de desempate: Quem atendeu há mais tempo
- Apenas barbeiros **ativos** são considerados

**Se `barbeiro_preferido` for informado:**
- Sistema tenta agendar com ele
- Se ocupado, retorna erro com sugestões de horário

---

## ✅ 3. Confirmar Comparecimento

**Endpoint:** `POST /api/agendamentos/confirmar-comparecimento`

**Descrição:** Registra se o cliente compareceu ou faltou.

**Body:**
```json
{
  "agendamento_id": "uuid-agendamento",
  "compareceu": true,  // true = compareceu, false = faltou
  "observacoes": "Cliente chegou 10min atrasado"  // Opcional
}
```

**Resposta de Sucesso:**
```json
{
  "success": true,
  "message": "Comparecimento confirmado com sucesso!",
  "data": {
    "agendamento_id": "uuid-agendamento",
    "compareceu": true,
    "status": "concluido",
    "checkin_at": "2025-12-20T14:05:00.000Z",
    "cliente": "João Silva",
    "barbeiro": "Hiago",
    "data": "2025-12-20",
    "hora": "14:00"
  }
}
```

---

## ❌ 4. Cancelar Agendamento

**Endpoint:** `DELETE /api/agendamentos/cancelar`

**Descrição:** Cancela um agendamento (valida prazo de 2h).

**Body:**
```json
{
  "agendamento_id": "uuid-agendamento",
  "motivo": "Cliente teve um imprevisto",  // Opcional
  "cancelado_por": "cliente",  // cliente | barbeiro | admin | sistema
  "forcar": false  // true = ignora validação de prazo (apenas admin)
}
```

**Resposta de Sucesso:**
```json
{
  "success": true,
  "message": "Agendamento cancelado com sucesso!",
  "data": {
    "agendamento_id": "uuid-agendamento",
    "status": "cancelado",
    "cancelado_por": "cliente",
    "motivo": "Cliente teve um imprevisto",
    "horas_antecedencia": "3.5",
    "cliente": "João Silva",
    "barbeiro": "Hiago",
    "data": "2025-12-20",
    "hora": "14:00",
    "valor_liberado": 125.00
  }
}
```

**Resposta de Erro (Prazo não permitido):**
```json
{
  "success": false,
  "message": "Cancelamento não permitido. É necessário cancelar com pelo menos 2h de antecedência",
  "errors": ["Faltam apenas 1.5h para o agendamento"],
  "data": {
    "prazo_minimo": 2,
    "horas_restantes": 1.5,
    "data_agendamento": "2025-12-20",
    "hora_agendamento": "14:00"
  }
}
```

---

## 🔔 Webhooks do Dashboard

O dashboard dispara webhooks para o N8N nas seguintes situações:

### Estrutura do Payload

**Todos os webhooks seguem este formato:**

```json
{
  "tipo": "confirmacao | lembrete_24h | lembrete_2h | followup_3d | followup_21d | cancelado",
  "agendamento_id": "uuid",
  "cliente": {
    "nome": "João Silva",
    "telefone": "11999999999"
  },
  "agendamento": {
    "data": "2025-12-20",
    "hora": "14:00",
    "barbeiro": "Hiago",
    "servicos": ["Corte", "Barba"],
    "valor_total": 125.00,
    "duracao_total": 60
  }
}
```

### Tipos de Notificação

| Tipo | Quando Dispara | Descrição |
|------|----------------|-----------|
| `confirmacao` | Imediatamente após criar agendamento | Confirmação do agendamento |
| `lembrete_24h` | 24h antes do agendamento | Lembrete 1 dia antes |
| `lembrete_2h` | 2h antes do agendamento | Lembrete urgente |
| `followup_3d` | 3 dias após atendimento | Pedir feedback |
| `followup_21d` | 21 dias após atendimento | Lembrete para reagendar |
| `cancelado` | Quando cancelado | Notificação de cancelamento |

### Exemplo de Payload Completo

**Confirmação de Agendamento:**
```json
{
  "tipo": "confirmacao",
  "agendamento_id": "a1b2c3d4-5678-90ab-cdef-1234567890ab",
  "cliente": {
    "nome": "João Silva",
    "telefone": "11999999999"
  },
  "agendamento": {
    "data": "2025-12-20",
    "hora": "14:00",
    "barbeiro": "Hiago",
    "servicos": ["Corte", "Barba Completa"],
    "valor_total": 125.00,
    "duracao_total": 60
  }
}
```

**Cancelamento:**
```json
{
  "tipo": "cancelado",
  "agendamento_id": "a1b2c3d4-5678-90ab-cdef-1234567890ab",
  "cliente": {
    "nome": "João Silva",
    "telefone": "11999999999"
  },
  "agendamento": {
    "data": "2025-12-20",
    "hora": "14:00",
    "barbeiro": "Hiago",
    "valor_total": 125.00
  },
  "cancelamento": {
    "cancelado_por": "cliente",
    "motivo": "Imprevisto",
    "horas_antecedencia": "3.5"
  }
}
```

---

## 🔄 Exemplos de Fluxos N8N

### Fluxo 1: Cliente Agenda via WhatsApp

```
┌─────────────────┐
│ 1. WhatsApp     │ Cliente envia mensagem "Quero agendar"
│    Trigger      │
└────────┬────────┘
         │
┌────────▼────────┐
│ 2. HTTP Request │ GET /api/agendamentos/horarios-disponiveis
│    Consultar    │ ?data=2025-12-20
│    Horários     │
└────────┬────────┘
         │
┌────────▼────────┐
│ 3. WhatsApp     │ Envia lista de horários disponíveis
│    Send Message │
└────────┬────────┘
         │ Cliente escolhe horário
┌────────▼────────┐
│ 4. HTTP Request │ POST /api/agendamentos/criar
│    Criar        │ Body: { cliente_nome, telefone, data, hora, servico_ids }
│    Agendamento  │
└────────┬────────┘
         │
┌────────▼────────┐
│ 5. Webhook      │ Dashboard dispara webhook "confirmacao"
│    Recebido     │
└────────┬────────┘
         │
┌────────▼────────┐
│ 6. WhatsApp     │ "✅ Agendamento confirmado para 20/12 às 14h com Hiago"
│    Confirmação  │
└─────────────────┘
```

### Fluxo 2: Lembrete Automático 24h Antes

```
┌─────────────────┐
│ 1. Vercel Cron  │ Executa de hora em hora (8h-20h)
│    Dashboard    │ GET /api/cron/lembretes
└────────┬────────┘
         │
┌────────▼────────┐
│ 2. Dashboard    │ Verifica agendamentos de amanhã
│    Processa     │ Dispara webhook "lembrete_24h"
└────────┬────────┘
         │
┌────────▼────────┐
│ 3. N8N Webhook  │ Recebe payload do tipo "lembrete_24h"
│    Trigger      │
└────────┬────────┘
         │
┌────────▼────────┐
│ 4. WhatsApp     │ "⏰ Lembrete: Amanhã às 14h você tem horário com Hiago"
│    Send Message │
└─────────────────┘
```

### Fluxo 3: Confirmação de Comparecimento

```
┌─────────────────┐
│ 1. WhatsApp     │ "Você compareceu ao atendimento?"
│    Pergunta     │
└────────┬────────┘
         │ Cliente responde "Sim"
┌────────▼────────┐
│ 2. HTTP Request │ POST /api/agendamentos/confirmar-comparecimento
│    Confirmar    │ Body: { agendamento_id, compareceu: true }
└────────┬────────┘
         │
┌────────▼────────┐
│ 3. WhatsApp     │ "✅ Ótimo! Obrigado pela confirmação!"
│    Resposta     │
└─────────────────┘
```

---

## ⚠️ Tratamento de Erros

### Códigos de Status HTTP

| Código | Significado | Ação |
|--------|-------------|------|
| 200 | Sucesso | Processar resposta |
| 201 | Criado com sucesso | Agendamento criado |
| 400 | Dados inválidos | Verificar body/params |
| 404 | Não encontrado | Barbeiro/agendamento inexistente |
| 409 | Conflito | Horário ocupado |
| 500 | Erro interno | Tentar novamente |

### Exemplo de Tratamento no N8N

**Node: IF (Verifica se sucesso)**
```javascript
// Em um node "IF"
{{ $json.success }} === true
```

**Se sucesso:**
- Envia WhatsApp de confirmação

**Se erro:**
- Loga o erro
- Envia mensagem alternativa ao cliente
- Notifica admin

### Retry em Caso de Falha

Configure o node HTTP Request:
```
Retry On Fail: ✅ Enabled
Max Tries: 3
Wait Between Tries: 5000ms
```

---

## 📊 Monitoramento

### Verificar Notificações Enviadas

```sql
SELECT
  tipo,
  COUNT(*) as total,
  COUNT(CASE WHEN status = 'enviado' THEN 1 END) as enviados,
  COUNT(CASE WHEN status = 'falhou' THEN 1 END) as falhas
FROM notificacoes_enviadas
WHERE enviado_em >= NOW() - INTERVAL '7 days'
GROUP BY tipo;
```

### Ver Histórico de um Agendamento

```sql
SELECT *
FROM notificacoes_enviadas
WHERE agendamento_id = 'uuid-aqui'
ORDER BY enviado_em DESC;
```

---

## 🔐 Segurança

### Variáveis de Ambiente Necessárias

**No Vercel:**
```env
# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=xxx
SUPABASE_SERVICE_ROLE_KEY=xxx

# Cron Job (Segurança)
CRON_SECRET=seu_token_secreto_aqui

# Google Calendar (Opcional)
GOOGLE_CLIENT_ID=xxx
GOOGLE_CLIENT_SECRET=xxx
```

### Proteção do Cron

O endpoint `/api/cron/lembretes` só pode ser chamado pelo Vercel Cron.

Verificação no código:
```typescript
const authHeader = request.headers.get('authorization')
if (authHeader !== `Bearer ${process.env.CRON_SECRET}`) {
  return 401 Unauthorized
}
```

---

## 📚 Recursos Adicionais

**Arquivos Importantes:**
- `src/lib/rodizio-notificacoes.sql` - Script SQL completo
- `src/app/api/agendamentos/criar/route.ts` - Endpoint de criação
- `src/app/api/cron/lembretes/route.ts` - Cron job
- `vercel.json` - Configuração do cron

**Suporte:**
- Dashboard: https://seu-dominio.vercel.app
- Supabase: https://supabase.com/dashboard

---

## ✅ Checklist de Integração

- [ ] Script SQL executado no Supabase
- [ ] Webhook URL configurado no dashboard
- [ ] Tipos de notificação ativados
- [ ] Vercel Cron configurado (CRON_SECRET)
- [ ] Fluxo N8N criado para receber webhooks
- [ ] Teste de criação de agendamento
- [ ] Teste de cancelamento
- [ ] Teste de confirmação de comparecimento
- [ ] Monitoramento ativo

---

**Documentação criada em:** 08/12/2025
**Versão do Sistema:** 1.0.0
