# Implementação do port HyperOS 2 / Android 15 para `a52sxq`

O projeto agora tem um caminho de port concreto, separado do build Android completo. A base de hardware é a árvore pública do Samsung SM-A528B, importada no commit `eb08adf5d14297a45448a34a2aa6bf81674c2b86`. Ela fornece `BoardConfig.mk`, `device.mk`, rootdir, fstab, overlays, libinit, sensores, GNSS, fingerprint, RIL e sepolicy.

O donor userspace é `CraftyOs_China_HOTFIX.zip`, validado como HyperOS 2.0.215/Android 15. O script `port_stage.sh` extrai `super.img.zst`, desmonta as partições lógicas com `tools/lpunpack.py` e guarda as imagens de userspace separadas.

A camada de hardware é obtida da release pública `A528BXXS6FXA1_BTU` para o SM-A528B. O script `fetch_a52sxq_native.sh` baixa e verifica `vendor.zip` e `kernel.tar`, extraindo `vendor.img`, `boot.img`, `dtbo.img`, `vendor_boot.img` e `vbmeta.img`.

| Camada | Origem usada | Estado |
| --- | --- | --- |
| Device tree | `Alone0316/android_device_samsung_a52sxq` | Importada |
| Kernel/DTB | `Alone0316/android_kernel_samsung_sm7325`, branch `sep-13.1/stock` | Referenciada; binários nativos são baixados no runner |
| Userspace | Donor HyperOS 2.0.215/Android 15 | Desmontado no modo `port-stage` |
| Vendor | `A528BXXS6FXA1_vendor.zip` | Baixado, hash validado e extraído no runner |
| Boot chain | `A528BXXS6FXA1_kernel.tar` | `boot`, `dtbo`, `vendor_boot`, `vbmeta` extraídos no runner |
| Flashabilidade | Não confirmada | Deliberadamente bloqueada até teste no A52s |

O workflow deve ser executado com `BUILD_MODE=port-stage` para produzir um `a52sxq-port-staging-<run>.tar.gz`. Esse artifact é um estágio de integração real, não uma ROM pronta: o kernel/vendor são Samsung, o userspace é HyperOS donor e ainda é necessário reconciliar AVB, SELinux, VINTF, init, propriedades, partições dinâmicas e compatibilidade de HAL antes de qualquer flash.

Não são usados `boot.img`, `dtbo.img`, kernel ou vendor Xiaomi. A etapa `full` continua reservada para uma árvore Android/HyperOS com `build/envsetup.sh`; o donor fornecido é um pacote pré-compilado e não contém essa árvore.
