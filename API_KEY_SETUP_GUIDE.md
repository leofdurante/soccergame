# 🔑 Guia Simples: Como Configurar a API Key

## ⚠️ Problema Atual
A API key não está sendo encontrada no app, mesmo que esteja configurada nos Build Settings.

## ✅ Solução Passo a Passo (5 minutos)

### Passo 1: Abra o Xcode
1. Abra o projeto `Soccer Trivia Game.xcodeproj`

### Passo 2: Selecione o Target "Soccerholic"
1. No **Project Navigator** (lado esquerdo), clique no **ícone azul** do projeto (primeiro item)
2. No painel central, selecione o **target "Soccerholic"** (não "Soccer Trivia Game")

### Passo 3: Vá para a Aba "Info"
1. No topo do painel, clique na aba **"Info"** (ao lado de "Build Settings", "Build Phases", etc.)

### Passo 4: Adicione a Chave da API
1. Você verá uma seção chamada **"Custom iOS Target Properties"** ou **"Info.plist values"**
2. Clique no botão **"+"** no canto inferior esquerdo dessa seção
3. Uma nova linha aparecerá. Configure:
   - **Key:** Digite `APISPORTS_KEY` (exatamente assim, sem aspas)
   - **Type:** Selecione `String` no dropdown
   - **Value:** Digite `f84462036aead4a1b5b24f5da9223911` (sua chave da API)

### Passo 5: Limpe e Reconstrua
1. No menu do Xcode: **Product → Clean Build Folder** (ou pressione `Shift + Cmd + K`)
2. Aguarde alguns segundos até a limpeza terminar
3. **Product → Build** (ou pressione `Cmd + B`)
4. **Product → Run** (ou pressione `Cmd + R`)

### Passo 6: Teste
1. Execute o app
2. Vá para "Guess the Player"
3. Clique em "START"
4. Agora deve carregar os jogadores sem erro! ✅

---

## 🎯 Método Alternativo (Se o Passo 4 Não Funcionar)

Se você não ver a opção de adicionar a chave na aba "Info", tente:

### Método Alternativo 1: Via Build Settings (User-Defined)
1. Selecione o target "Soccerholic"
2. Vá para a aba **"Build Settings"**
3. No topo, certifique-se que está mostrando **"All"** (não "Basic")
4. Clique no botão **"+"** no topo → **"Add User-Defined Setting"**
5. Digite: `APISPORTS_KEY`
6. Pressione Enter
7. No valor, digite: `f84462036aead4a1b5b24f5da9223911`

Agora, modifique o Build Setting existente:
8. Procure por `INFOPLIST_KEY_APISPORTS_KEY` na busca
9. Clique duas vezes no valor
10. Mude de `f84462036aead4a1b5b24f5da9223911` para `$(APISPORTS_KEY)`

### Método Alternativo 2: Criar Info.plist Manual
Se nada funcionar, podemos criar um Info.plist manual. Mas primeiro tente os métodos acima!

---

## 📸 Como Deve Ficar

Na aba "Info", você deve ver algo assim:

```
Custom iOS Target Properties
├── Bundle display name: Soccerholic
├── Bundle identifier: com.leodurante.Soccerholic
└── APISPORTS_KEY: f84462036aead4a1b5b24f5da9223911  ← ESTA LINHA!
```

---

## ❓ Ainda Não Funciona?

1. **Verifique o Console do Xcode:**
   - Quando o app abrir, veja o console (parte inferior do Xcode)
   - Procure por mensagens começando com `✅` ou `❌`
   - Isso mostrará o que está acontecendo

2. **Verifique se está usando o target correto:**
   - No topo do Xcode, certifique-se que o **scheme** selecionado é **"Soccerholic"**
   - Não deve ser "Soccer Trivia Game"

3. **Entre em contato:**
   - Me envie uma captura de tela da aba "Info" do target "Soccerholic"
   - E me diga o que aparece no console do Xcode

---

## ✨ Depois que Funcionar

Uma vez configurado, você pode usar o modo "Guess the Player" normalmente:
- O app buscará 10 jogadores aleatórios da API
- Você terá 30 segundos por rodada
- Digite o nome do jogador na foto
- O jogo valida automaticamente e avança

