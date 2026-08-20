# Arquivos proprietários do `a52sxq`

Este diretório recebe arquivos extraídos de uma instalação autorizada do Samsung Galaxy A52s ou de uma fonte redistribuível compatível. Os arquivos não devem ser commitados por padrão. O pipeline espera um `proprietary-manifest.txt` gerado por `scripts/extract.sh` e valida seus hashes antes de empacotar.

Para uma tentativa completa, o usuário precisa fornecer os blobs do A52s e a origem autorizada do userspace HyperOS como artifact privado ou secrets do GitHub. A infraestrutura pública, sozinha, não contém esses dados.
