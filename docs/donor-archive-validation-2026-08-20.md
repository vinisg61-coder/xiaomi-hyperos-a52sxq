# Validação do donor HyperOS 2 — 2026-08-20

O workflow `a52sxq bring-up build` executou o modo `donor-validate` no run [32388049257](https://github.com/vinisg61-coder/xiaomi-hyperos-a52sxq/actions/runs/32388049257), diretamente no runner do GitHub. O arquivo não foi baixado no dispositivo do usuário.

| Campo | Resultado |
| --- | --- |
| Arquivo | `CraftyOs_China_HOTFIX.zip` |
| URL | `https://pixeldrain.com/api/file/s12gJsEx?download=1` |
| Tamanho | `4,338,708,939` bytes |
| SHA256 | `c84941ebece1d99101ae19ffda7f7a4ce911433c49e051d693d7de869fa46edf` |
| ZIP íntegro | Sim; `unzip -tq` passou |
| Android/HyperOS declarado | Android 15 / HyperOS 2.0.215, conforme a postagem pública do XDA [1] |
| Donor de hardware | Redmi Note 10 Pro/Max (`sweet`), não Samsung A52s |
| Imagens encontradas | `boot.img`, `dtbo.img`, `logo.img`, `super.img.zst` |
| Resultado do pacote | `kind=bringup-bundle`, `images=0` |
| Flashável no A52s | Não |
| Boot confirmado | Não |

A listagem do ZIP contém 19 entradas, incluindo `boot.img` de 134 MiB, `dtbo.img` de 32 MiB, `logo.img` de aproximadamente 29,7 MiB e `super.img.zst` de aproximadamente 4,02 GiB. O pipeline tratou o archive como **dados**: calculou hash, testou a integridade e verificou a presença dos nomes esperados, mas não executou `update-binary`, não usou o kernel Xiaomi e não marcou o bundle como ROM flashável.

O hash acima deve permanecer fixado no workflow. Se o arquivo remoto mudar, o job deve falhar por divergência de tamanho ou SHA256. O donor pode fornecer material de userspace para investigação, mas não substitui device tree, kernel, DTB/DTBO, vendor, HALs ou firmware nativos do `a52sxq`.

## Referências

[1]: https://xdaforums.com/t/update-rom-15-hyperos-2-0-215-port-stable.4774141/ "Post público do XDA sobre CraftyOS HyperOS 2.0.215 para Redmi Note 10 Pro"
[2]: https://pixeldrain.com/u/s12gJsEx "Arquivo público CraftyOs_China_HOTFIX.zip"
[3]: https://github.com/vbajs/android_kernel_xiaomi_sweet/tree/15/miui "Kernel source do donor sweet; não compatível com o A52s"
