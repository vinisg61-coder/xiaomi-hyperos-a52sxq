# Vendor Samsung A52s — interface de integração

O vendor do A52s deve ser obtido de uma fonte pública redistribuível compatível ou de um dump extraído de um dispositivo que o usuário possui. Este repositório não embute firmware nem blobs proprietários. O script `extract.sh` copia apenas arquivos fornecidos explicitamente e cria um manifesto com SHA-256.

Os componentes nativos do A52s têm precedência para câmera, áudio, display/HWC, sensores, fingerprint, RIL/modem, Wi-Fi, Bluetooth, NFC e carregamento. O userspace Xiaomi não deve substituir essas bibliotecas sem uma hipótese de compatibilidade documentada e um teste correspondente.
