# Kernel Samsung A52s — contrato de integração

O kernel, device tree blob e overlays de device tree devem corresponder ao Samsung Galaxy A52s (`a52sxq`) e ao firmware/bootloader usado no teste. A referência pública inicial é o kernel comum Samsung SM7325 indicado em `config/sources.env`, mas ela só será considerada válida depois de conferir configuração, defconfig, formato da imagem, módulos e compatibilidade com o boot chain do SM-A528B.

O pipeline deve construir ou importar os artefatos `Image`/`Image.gz` e DTB/DTBO conforme a árvore real. Enquanto os artefatos não estiverem presentes, `build.sh` não gera uma ROM flashável.
