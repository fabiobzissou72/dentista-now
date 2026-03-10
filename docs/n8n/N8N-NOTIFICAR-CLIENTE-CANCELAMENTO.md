# 📲 Notificação Automática de Cancelamento para Cliente

Sistema automático para avisar o cliente quando um agendamento for cancelado pelo barbeiro.

---

## 🔄 Como Funciona

```
Barbeiro cancela → API dispara webhook → N8N recebe → WhatsApp para cliente
```

---

## 📋 Passo a Passo Completo

### 1️⃣ Configurar Webhook URL no Supabase

A API já está preparada para disparar webhooks! Você só precisa configurar a URL.

**Acesse o Supabase:**
1. Vá na tabela `configuracoes`
2. Localize o registro (normalmente id = 1)
3. Configure os campos:

| Campo | Valor | Descrição |
|-------|-------|-----------|
| `webhook_url` | `https://seu-n8n.com/webhook/cancelamento` | URL do webhook do N8N |
| `notif_cancelamento` | `true` | Ativar notificações de cancelamento |

**SQL para configurar:**
```sql
UPDATE configuracoes
SET
  webhook_url = 'https://seu-n8n.com/webhook/cancelamento',
  notif_cancelamento = true
WHERE id = 1;
```

---

### 2️⃣ Criar Workflow no N8N

#### Node 1: Webhook (Trigger)

**Configuração:**
```
Nome: Webhook Cancelamento
Método: POST
Caminho: /webhook/cancelamento
```

**Dados recebidos da API:**
```json
{
  "tipo": "cancelamento",
  "agendamento_id": "abc123-uuid",
  "cliente": {
    "nome": "João Silva",
    "telefone": "11999999999"
  },
  "agendamento": {
    "data": "21/12/2024",
    "hora": "14:00",
    "barbeiro": "Hiago",
    "cancelado_por": "barbeiro (Hiago)",
    "motivo": "Cancelado pelo barbeiro via WhatsApp"
  }
}
```

---

#### Node 2: Montar Mensagem para Cliente

**Code Node:**
```javascript
const dados = $input.item.json;

// Extrair informações
const cliente = dados.cliente.nome;
const data = dados.agendamento.data;
const hora = dados.agendamento.hora;
const barbeiro = dados.agendamento.barbeiro;
const motivo = dados.agendamento.motivo || "Imprevisto";

// Montar mensagem amigável
const mensagem = `❌ *Agendamento Cancelado*\n\n` +
  `Olá ${cliente.split(' ')[0]},\n\n` +
  `Infelizmente precisamos cancelar seu agendamento:\n\n` +
  `📅 *Data:* ${data}\n` +
  `🕐 *Horário:* ${hora}\n` +
  `💈 *Barbeiro:* ${barbeiro}\n\n` +
  `📞 *Entre em contato para reagendar:*\n` +
  `Ligue: (11) 98765-4321\n` +
  `WhatsApp: wa.me/5511987654321\n\n` +
  `Pedimos desculpas pelo inconveniente! 🙏`;

return {
  json: {
    telefone: dados.cliente.telefone,
    mensagem: mensagem
  }
};
```

---

#### Node 3: Enviar WhatsApp

**WhatsApp Node:**
```
Para: {{ $json.telefone }}
Mensagem: {{ $json.mensagem }}
```

**Mensagem enviada ao cliente:**
```
❌ *Agendamento Cancelado*

Olá João,

Infelizmente precisamos cancelar seu agendamento:

📅 *Data:* 21/12/2024
🕐 *Horário:* 14:00
💈 *Barbeiro:* Hiago

📞 *Entre em contato para reagendar:*
Ligue: (11) 98765-4321
WhatsApp: wa.me/5511987654321

Pedimos desculpas pelo inconveniente! 🙏
```

---

## 🎨 Personalizar Mensagem

### Opção 1: Mensagem Simples
```javascript
const mensagem = `❌ Olá ${cliente.split(' ')[0]}, ` +
  `seu agendamento do dia ${data} às ${hora} com ${barbeiro} ` +
  `foi cancelado. Por favor, entre em contato para reagendar.`;
```

---

### Opção 2: Mensagem com Motivo
```javascript
const mensagem = `❌ *Cancelamento de Agendamento*\n\n` +
  `Olá ${cliente.split(' ')[0]}!\n\n` +
  `Seu agendamento foi cancelado:\n` +
  `📅 ${data} às ${hora}\n` +
  `💈 Com ${barbeiro}\n\n` +
  `*Motivo:* ${motivo}\n\n` +
  `🔄 *Reagende pelo WhatsApp:*\n` +
  `wa.me/5511987654321`;
```

---

### Opção 3: Mensagem com Botões
```javascript
const mensagem = `❌ *Cancelamento*\n\n` +
  `Olá ${cliente.split(' ')[0]},\n\n` +
  `Cancelamos seu agendamento de ${data} às ${hora}.\n\n` +
  `Clique abaixo para reagendar:`;

const botoes = [
  {
    id: 'reagendar',
    title: '📅 Reagendar Agora'
  },
  {
    id: 'falar_atendente',
    title: '👤 Falar com Atendente'
  }
];

return {
  json: {
    telefone: dados.cliente.telefone,
    mensagem: mensagem,
    botoes: botoes
  }
};
```

---

## 🔧 Fluxograma Completo N8N

```
┌──────────────────┐
│ Webhook Trigger  │ ← API envia dados do cancelamento
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Code Node        │ ← Monta mensagem para cliente
│ Montar Mensagem  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ WhatsApp         │ ← Envia para o cliente
│ Enviar Mensagem  │
└──────────────────┘
```

---

## 🧪 Testar o Webhook

### Teste Manual no N8N

1. **Copie a URL do webhook** no N8N
   - Exemplo: `https://seu-n8n.com/webhook/cancelamento`

2. **Configure no Supabase:**
   ```sql
   UPDATE configuracoes
   SET webhook_url = 'https://seu-n8n.com/webhook/cancelamento'
   WHERE id = 1;
   ```

3. **Teste com cURL:**
   ```bash
   curl -X POST https://seu-n8n.com/webhook/cancelamento \
     -H "Content-Type: application/json" \
     -d '{
       "tipo": "cancelamento",
       "cliente": {
         "nome": "Teste Silva",
         "telefone": "11999999999"
       },
       "agendamento": {
         "data": "21/12/2024",
         "hora": "14:00",
         "barbeiro": "Hiago",
         "cancelado_por": "barbeiro (Hiago)",
         "motivo": "Teste de notificação"
       }
     }'
   ```

4. **Cancele um agendamento real** pela API e veja se o cliente recebe!

---

## 📊 Payload Completo da API

Quando um agendamento é cancelado, a API envia este JSON para o webhook:

```json
{
  "tipo": "cancelamento",
  "agendamento_id": "abc123-def456-uuid",
  "cliente": {
    "nome": "João Silva",
    "telefone": "11999999999"
  },
  "agendamento": {
    "data": "21/12/2024",
    "hora": "14:00",
    "barbeiro": "Hiago",
    "cancelado_por": "barbeiro (Hiago)",
    "motivo": "Cancelado pelo barbeiro via WhatsApp"
  }
}
```

**Campos disponíveis:**
- `tipo`: Sempre "cancelamento"
- `agendamento_id`: UUID do agendamento
- `cliente.nome`: Nome completo do cliente
- `cliente.telefone`: Telefone do cliente
- `agendamento.data`: Data do agendamento (DD/MM/YYYY)
- `agendamento.hora`: Hora do agendamento (HH:MM)
- `agendamento.barbeiro`: Nome do barbeiro
- `agendamento.cancelado_por`: Quem cancelou
- `agendamento.motivo`: Motivo do cancelamento

---

## 🎯 Cenários de Uso

### Cenário 1: Barbeiro cancela via WhatsApp
```
Barbeiro: "Cancela o agendamento do João às 14h"
  ↓
API cancela agendamento
  ↓
API dispara webhook para N8N
  ↓
N8N envia WhatsApp para João
  ↓
João recebe: "❌ Seu agendamento foi cancelado..."
```

---

### Cenário 2: Barbeiro cancela com botão (ID)
```
Barbeiro clica: [❌ 14:00 - João]
  ↓
N8N chama: POST /cancelar { agendamento_id: "abc123" }
  ↓
API cancela e dispara webhook
  ↓
Cliente recebe notificação automática
```

---

## ⚙️ Configurações Avançadas

### Adicionar Log de Notificações

**Code Node antes do WhatsApp:**
```javascript
const dados = $input.item.json;

// Log para monitoramento
console.log('📤 Enviando notificação de cancelamento:', {
  cliente: dados.cliente.nome,
  telefone: dados.cliente.telefone,
  data: dados.agendamento.data,
  hora: dados.agendamento.hora
});

// Salvar no banco (opcional)
// Você pode criar uma tabela "notificacoes_enviadas"

return { json: dados };
```

---

### Tratamento de Erros

**Function Node após WhatsApp:**
```javascript
const resultado = $input.item.json;

if (resultado.error) {
  console.error('❌ Erro ao enviar WhatsApp:', {
    cliente: $node["Montar Mensagem"].json.telefone,
    erro: resultado.error
  });

  // Opcional: Tentar SMS como fallback
  // Ou enviar email

  return {
    json: {
      status: 'erro',
      fallback: 'sms'
    }
  };
}

return {
  json: {
    status: 'sucesso',
    enviado_em: new Date().toISOString()
  }
};
```

---

### Horário Comercial

Evita enviar notificações muito tarde/cedo:

**Code Node antes de enviar:**
```javascript
const dados = $input.item.json;

// Obter hora atual de Brasília
const agora = new Date(new Date().toLocaleString('en-US', { timeZone: 'America/Sao_Paulo' }));
const hora = agora.getHours();

// Horário comercial: 8h às 20h
if (hora < 8 || hora >= 20) {
  console.log('⏰ Fora do horário comercial. Agendando para amanhã 9h.');

  // Agendar para próximo dia útil às 9h
  // (Usar node de Schedule ou Wait do N8N)

  return {
    json: {
      ...dados,
      agendar_para: 'proximo_dia_util_9h'
    }
  };
}

// Horário OK, enviar agora
return { json: dados };
```

---

## 📝 Checklist de Configuração

- [ ] Configurar `webhook_url` no Supabase (tabela configuracoes)
- [ ] Ativar `notif_cancelamento = true` no Supabase
- [ ] Criar webhook no N8N (rota `/webhook/cancelamento`)
- [ ] Criar node de montagem de mensagem
- [ ] Configurar node WhatsApp
- [ ] Testar com cURL
- [ ] Cancelar um agendamento real e verificar se cliente recebe
- [ ] Ajustar mensagem conforme necessário
- [ ] (Opcional) Adicionar logs
- [ ] (Opcional) Adicionar tratamento de erros
- [ ] (Opcional) Configurar horário comercial

---

## 🚨 Importante

1. **Webhook URL**: Deve ser HTTPS (não HTTP)
2. **Telefone**: Formato com DDI (55 11 999999999)
3. **Privacidade**: Não envie dados sensíveis no webhook
4. **Fallback**: Considere SMS ou email se WhatsApp falhar
5. **Logs**: Monitore para garantir que clientes recebem

---

## 💡 Dicas Extras

### Reagendamento Rápido

Adicione link direto para reagendar:

```javascript
const linkReagendar = `https://vincidentista.com.br/agendar?barbeiro=${barbeiro}`;

const mensagem = `❌ *Cancelamento*\n\n` +
  `Seu agendamento de ${data} às ${hora} foi cancelado.\n\n` +
  `🔄 *Reagende aqui:*\n${linkReagendar}`;
```

### Cupom de Desconto

Ofereça desconto para compensar:

```javascript
const mensagem = `❌ *Cancelamento*\n\n` +
  `Lamentamos cancelar seu agendamento de ${data}.\n\n` +
  `Como desculpas, ganhe *10% OFF* no próximo:\n` +
  `Cupom: DESCULPA10\n\n` +
  `Válido por 30 dias! 🎁`;
```

---

**Documentação criada em:** 21/12/2024
**Versão:** 1.0 - Notificação Automática de Cancelamento
