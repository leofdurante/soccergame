# Soccerholic Target Setup Guide

## ✅ O que já foi feito:
- Target "Soccerholic" criado
- SoccerholicApp.swift atualizado para usar Firebase e HomeView

## 🔧 O que você precisa fazer no Xcode:

### 1. Adicionar Arquivos ao Target Soccerholic

No Xcode:
1. **Selecione a pasta "Soccer Trivia Game"** no Project Navigator (à esquerda)
2. **Selecione todos os arquivos Swift** na pasta "Soccer Trivia Game":
   - Models/ (todos os arquivos)
   - Services/ (todos os arquivos)
   - ViewModels/ (todos os arquivos)
   - Views/ (todos os arquivos)
   - Theme/ (todos os arquivos)
   - SoccerTriviaApp.swift (não precisa, já temos SoccerholicApp.swift)
3. **No File Inspector** (painel direito, ⌥⌘1):
   - Em "Target Membership", marque ✅ **Soccerholic**
   - Desmarque qualquer outro target se necessário

4. **Adicionar Resources:**
   - Selecione a pasta `images/`
   - No File Inspector → Target Membership → ✅ Soccerholic
   - Selecione `Resources/questions.json`
   - No File Inspector → Target Membership → ✅ Soccerholic
   - Selecione `Resources/*.mp3` (arquivos de som)
   - No File Inspector → Target Membership → ✅ Soccerholic
   - Selecione `GoogleService-Info.plist`
   - No File Inspector → Target Membership → ✅ Soccerholic

### 2. Configurar Info.plist para API Key

Como o target usa `GENERATE_INFOPLIST_FILE = YES`, você precisa adicionar a chave via Build Settings:

1. **No Xcode, selecione o target "Soccerholic"**
2. **Vá para a aba "Build Settings"**
3. **Pesquise por "Info.plist"** na barra de busca
4. **Adicione a chave da API:**
   - Clique no botão **"+"** ao lado de "Info.plist Values"
   - Adicione: `INFOPLIST_KEY_APISPORTS_KEY` (Key)
   - Valor: `$(APISPORTS_KEY)` ou sua chave diretamente

   **OU, mais fácil:**
   - Vá para a aba **"Info"** (não Build Settings)
   - Em "Custom iOS Target Properties"
   - Clique no botão **"+"** para adicionar uma nova entrada
   - Key: `APISPORTS_KEY`
   - Type: `String`
   - Value: `f84462036aead4a1b5b24f5da9223911` (sua chave da API)

### 3. Adicionar Firebase Package Dependencies

1. **Selecione o projeto** (ícone azul) no Project Navigator
2. **Selecione o target "Soccerholic"**
3. **Vá para "General" → "Frameworks, Libraries, and Embedded Content"**
4. **Clique no botão "+"**
5. **Adicione os pacotes Firebase:**
   - FirebaseAuth
   - FirebaseFirestore
   - FirebaseFirestoreSwift
   - FirebaseCore

   (Se não aparecerem, vá para Package Dependencies e adicione o pacote Firebase iOS SDK)

### 4. Verificar Bundle Identifier

1. **Selecione o target "Soccerholic"**
2. **Vá para "General"**
3. **Verifique o Bundle Identifier:** deve ser `com.leodurante.Soccerholic`
4. **Atualize o GoogleService-Info.plist** se necessário:
   - Abra `GoogleService-Info.plist`
   - Verifique se o `BUNDLE_ID` corresponde a `com.leodurante.Soccerholic`

### 5. Criar Scheme (se não existir)

1. **No topo do Xcode, clique no nome do scheme atual**
2. **Selecione "Manage Schemes..."**
3. **Verifique se existe um scheme "Soccerholic"**
4. **Se não existir:**
   - Clique no botão **"+"**
   - Nome: `Soccerholic`
   - Target: `Soccerholic`
   - ✅ Shared (marque esta opção)
   - Clique "OK"

### 6. Testar

1. **Selecione o scheme "Soccerholic"** no topo do Xcode
2. **Selecione um simulador** (ex: "iPhone 16 Pro")
3. **Product → Clean Build Folder** (⇧⌘K)
4. **Product → Build** (⌘B)
5. **Product → Run** (⌘R)

## ⚠️ Problemas Comuns

### Erro: "Cannot find 'HomeView' in scope"
- ✅ Certifique-se de que todos os arquivos da pasta "Views" estão no target Soccerholic

### Erro: "Cannot find 'AuthService' in scope"
- ✅ Certifique-se de que todos os arquivos da pasta "Services" estão no target Soccerholic

### Erro: "API key not configured"
- ✅ Verifique que adicionou `APISPORTS_KEY` no Info tab (não Build Settings)
- ✅ Limpe o build folder e recompile

### Erro: "Firebase not found"
- ✅ Adicione o Firebase iOS SDK via Package Dependencies
- ✅ Adicione os produtos Firebase ao target Soccerholic

