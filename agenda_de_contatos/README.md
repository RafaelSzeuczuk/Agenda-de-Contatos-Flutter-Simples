# Agenda de Contatos (Android)

Aplicativo Flutter de agenda de contatos com armazenamento local SQLite.

## Recursos

- Cadastro, edição, exclusão, ordenação e ligação para contatos.
- Foto do contato capturada diretamente pela câmera do Android.
- A opção Galeria usa o seletor nativo de fotos do Android quando disponível, com fallback compatível em versões antigas.
- E-mail normalizado automaticamente em letras minúsculas, sem espaços, e validado quando informado. E-mail não possui uma máscara fixa como telefone ou CEP.
- Telefone com máscara `(00) 00000-0000`.
- Consulta de CEP pela API pública ViaCEP, com preenchimento de logradouro, bairro, cidade e UF.
- Campo independente para o número do endereço.
- Campo opcional para complemento do endereço.
- Migração automática do banco local já existente para os novos campos, preservando os contatos salvos.

## Executar no Android

1. Abra a pasta do projeto no Android Studio com o plugin Flutter instalado.
2. Use Flutter 3.44 ou mais recente e Dart 3.12 ou mais recente.
3. Conecte um dispositivo/emulador Android e execute `flutter pub get`.
4. Inicie o app com `flutter run` ou gere um APK com `flutter build apk`.

A consulta ViaCEP precisa de conexão com a internet. A captura de imagem usa o app de câmera disponível no Android.
