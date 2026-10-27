# Auditoria do desktop, da NVIDIA e do workflow no Arch Linux

Data: 26 de outubro de 2026

Escopo: auditoria somente de leitura das configurações fonte do chezmoi, da sessão Arch Linux/Xfce/Compiz e do hardware gráfico; pesquisa de opções para aproximar o workflow Linux do macOS, preservando desempenho e animações.

## Diagnóstico principal

Há dois problemas concretos nesta configuração: não há gerenciador de janelas ativo na sessão examinada, e o monitor principal está operando a 59,95 Hz apesar de oferecer um modo de 165,08 Hz. A RTX 3060 e o driver NVIDIA estão funcionando. O limitador visual observado é a configuração da sessão e das telas, não falta de potência gráfica.

## Compiz e decoração das janelas

A configuração do Compiz habilita o plugin decor e aponta para /usr/bin/compiz-decorator --metacity-theme Numix --replace, em private_dot_config/private_compiz-1/private_compizconfig/Default.ini. O comando compiz-decorator é válido para o Compiz 0.9: procura um decorador disponível, como o GTK Window Decorator. O tema numix-gtk-theme já está instalado.

O pacote compiz, porém, não está instalado; nem Compiz, XFWM nem um decorador foram encontrados em execução durante a consulta da sessão X11. A propriedade _NET_SUPPORTING_WM_CHECK também não estava presente na janela raiz. Isso indica que a sessão examinada estava sem um gerenciador de janelas reconhecido pelo protocolo EWMH, o que explica as janelas sem bordas. A configuração não exige Emerald: a preferência é manter as funções do Compiz e o decorador GTK.

Há também uma configuração de sessão suspeita em private_dot_config/xfce4/xfconf/private_xfce-perchannel-xml/xfce4-session.xml: Client0_Command contém o array compiz, xfwm4. O Xfce trata esse array como um comando e seus argumentos; xfwm4 não é um fallback. Assim, é necessário configurar o início do Compiz como um comando válido e assegurar que não se iniciem Compiz e XFWM como gerenciadores concorrentes. O código de inicialização do Xfce confirma como o comando de sessão é passado ao processo: https://github.com/xfce-mirror/xfce4-session/blob/master/xfce4-session/xfsm-manager.c

O pacote AUR apropriado para a família atual é compiz 0.9.14.2. Ele fornece Compiz, plugins, CCSM e GTK Window Decorator com suporte Metacity. Não misturar com compiz-core, compiz-gtk e compiz-fusion-plugins-*, que pertencem à família 0.8 e conflitam com o pacote atual. O comando previsto para instalar, caso escolhido, é:

    yay -S --needed compiz

Depois da instalação, testar a inicialização do Compiz na sessão gráfica, verificar que ele substituiu o XFWM e confirmar a presença de decoração. Só então consolidar o comando de início no chezmoi. O comando decorador configurado já é reconhecido pelo ArchWiki; não há motivo para trocar para Emerald. Fonte: https://wiki.archlinux.org/title/Compiz

## Monitor, Compiz e fluidez das animações

A RTX está ligada a dois monitores pela X11:

| Saída | Modo observado | Posição observada | Taxa atual | Taxas disponíveis relevantes |
|---|---:|---:|---:|---:|
| DP-2 | 2560×1440 | +0+0 | 59,95 Hz | 165,08; 143,91; 120; 59,95 Hz |
| DP-0 | 1920×1080 | +2560+0 | 60 Hz | 60 Hz |

O monitor 2560×1440 deve ser configurado para 165,08 Hz nas configurações de tela do Xfce se esse for o modo desejado. A configuração do Compiz, porém, lista a geometria antiga como 2560x1440+0+1080;1920x1080+320+0, isto é, empilhada e com sobreposição; a geometria atual é lado a lado. Atualizar as posições de saída do Compiz para corresponder à disposição real ajuda a manter a configuração reproduzível.

No plugin Composite, detect_refresh_rate está desligado e a taxa fixa está em 165 Hz. O VSync está ligado. A taxa fixa pode fazer sentido com o monitor principal em 165 Hz, mas deve ser conferida depois de selecionar o modo correto, particularmente por haver um segundo monitor a 60 Hz. Preserve as animações atuais enquanto corrige modo e apresentação: abertura e fechamento duram 100–150 ms, minimização 200 ms. A documentação do Compiz explica que o VSync pode reduzir tearing, embora possa deixar o movimento menos responsivo se a sincronização ficar mal configurada. Fontes: https://wiki.archlinux.org/title/Compiz e https://www.compiz-fusion.org/wiki_subdomain/generaloptions.html

ForceFullCompositionPipeline não é uma otimização universal. A opção força uma etapa de composição no driver e pode alterar latência; testar somente se tearing persistir depois dos ajustes de taxa e do Compiz. Documentação NVIDIA 615.78.08: https://download.nvidia.com/XFree86/Linux-x86_64/615.78.08/README/xconfigoptions.html

## NVIDIA: estado encontrado e recursos

Hardware e software verificados:

- GPU: NVIDIA GeForce RTX 3060 LHR, GA106, 12 GiB de VRAM.
- Driver: nvidia-open / nvidia-utils 615.78.08.
- Kernel Arch 7.2.11.
- Driver de kernel ativo; nvidia-drm.modeset=1 e nvidia_drm.fbdev=1 ativos.
- nvidia-smi se comunica com a GPU; Vulkan 1.4 enumera a RTX 3060 e o driver NVIDIA.
- Em repouso: P8, 0% de utilização, cerca de 14,36 W de um limite de 170 W. Esse é um estado eficiente de repouso, não sinal de subutilização que exija forçar clocks.
- VSync do Compiz ligado. Não há no repositório uma configuração NVIDIA personalizada para Coolbits, clocks fixos ou composição forçada.
- Suspensão: UseKernelSuspendNotifiers: 1, PreserveVideoMemoryAllocations: 2 e TemporaryFilePath: /var/tmp. Para esta versão, preservar a memória de vídeo é automático com o módulo open e os notifiers. Não habilitar serviços antigos de suspensão sem um problema observado.

O driver aberto é apropriado para a RTX 3060. Não há indício de recurso de aceleração 3D bloqueado por um ajuste do chezmoi. Também não se deve tentar manter a GPU no estado de potência máximo em repouso.

Recursos de vídeo da RTX 30:

- NVDEC decodifica AV1, H.264 e HEVC, entre outros formatos.
- NVENC codifica H.264 e HEVC; a RTX 3060 não codifica AV1.
- O mpv já está instalado e pode ser testado com mpv --hwdec=auto arquivo, confirmando no log que o decoder por hardware está em uso. auto mantém a possibilidade de configuração compartilhada com macOS.
- OBS está instalado; selecionar NVENC H.264 ou HEVC para gravação/streaming libera trabalho da CPU. CUDA Toolkit completo não é necessário apenas para NVENC.
- Firefox pode usar libva-nvidia-driver para decodificação de vídeo por hardware, mas a configuração atual desse caminho pede MOZ_DISABLE_RDD_SANDBOX=1. Como isso reduz o isolamento do processo de decodificação, tratar como escolha opcional e avaliar esse custo antes de aplicar.

Fontes: https://www.nvidia.com/en-us/geforce/news/rtx-30-series-community-qa/ ; https://obsproject.com/kb/hardware-encoding ; https://archlinux.org/packages/extra/x86_64/libva-nvidia-driver/ ; https://github.com/elFarto/nvidia-vaapi-driver

## Melhorias de workflow alinhadas ao macOS

### Prioridade alta

1. **Vicinae / Raycast**
   - Já há configuração de tema e exclusão de janelas do tiling em private_dot_config/vicinae/settings.json e private_dot_config/cortile/config.toml.
   - Ctrl+Space já está configurado para vicinae toggle, e há um launcher no painel.
   - O binário não foi encontrado instalado e o pacote não consta em dot_Pacmanfile; não foi encontrado autostart gerenciado.
   - É a oportunidade mais direta para completar uma experiência semelhante ao Raycast. Vicinae documenta controle de janelas no X11 por XCB, embora descreva o suporte X11 como menos polido que o Wayland. Compatibilidade com extensões Raycast é parcial.
   - Fontes: https://docs.vicinae.com/ ; https://docs.vicinae.com/window ; https://docs.vicinae.com/os-support ; https://docs.vicinae.com/install-extensions

2. **Espanso no ambiente correto**
   - dot_Pacmanfile declara espanso-wayland e essa variante está instalada.
   - A sessão observada é X11/Compiz, não Wayland. Os snippets do Espanso já existem no chezmoi.
   - Substituir pela compilação/distribuição X11 apropriada e gerenciar o início da sessão. Confirmar o nome real do pacote no yay antes de registrá-lo; não presumir que o nome de uma distribuição RPM também seja o nome do pacote Arch.
   - Fonte: https://espanso.org/install/

3. **Clipboard do tmux**
   - Em private_dot_config/tmux/tmux.conf.tmpl, o tmux escolhe wl-copy apenas porque o executável existe. wl-copy e xclip estão instalados, mas a sessão ativa é X11. Selecionar o backend pela variável de sessão (WAYLAND_DISPLAY/DISPLAY) ou por OSC 52, para não tentar enviar texto a um compositor Wayland ausente.

4. **Seletor de sessões do Sesh**
   - A tecla C-o executa sesh connect sem argumento. A versão instalada responde que é obrigatório informar pelo menos uma sessão.
   - Usar um seletor com fzf e sesh list e enviar a escolha para sesh connect. fzf, zoxide e sesh já estão presentes.
   - Fonte de integração: https://github.com/joshmedeski/sesh#tmux--fzf

5. **Conflitos entre Cortile e Compiz**
   - Cortile está com tiling habilitado; o Compiz também oferece Grid, encaixe nas bordas e redimensionamento. Definir qual componente controla o tiling ou limitar a atuação de um deles.
   - Super+Tab ativa tanto o Scale quanto o Static Switcher do Compiz.
   - Super+Shift+D alterna as decorações no Cortile e também reduz janelas secundárias. Pode ocultar bordas acidentalmente. Remapear essa tecla.
   - Super+H minimiza uma janela no Compiz e reduz a proporção do Cortile. Escolher uma função para cada atalho.
   - As animações existentes são rápidas e não precisam ser removidas para ganhar desempenho.
   - Fonte do projeto Cortile: https://github.com/leukipp/cortile

### Prioridade média

6. **Clipboard visual e captura de tela**
   - Clipman já está no painel e oferece histórico, busca fuzzy e colagem. Acrescentar outro gerenciador de clipboard pode duplicar a função; escolher Clipman ou o histórico do Vicinae como interface principal.
   - Flameshot pode aproximar o fluxo de captura anotada do CleanShot, com atalho do Xfce. Está disponível no repositório oficial, mas não instalado.
   - Fontes: https://docs.xfce.org/panel-plugins/xfce4-clipman-plugin/start ; https://flameshot.org/

7. **Ghostty Quick Terminal**
   - O Ghostty já tem configuração de quick terminal para macOS. No Linux, esse recurso depende do Wayland/wlr-layer-shell e não se aplica à sessão X11/Compiz.
   - Mantendo X11, preferir atalho do Xfce para abrir/focar Ghostty, ou testar xfce4-terminal --drop-down.
   - Fonte: https://ghostty.org/docs/config/keybind/reference#toggle_quick_terminal

8. **PowerKit no tmux**
   - O backend de atualização de pacotes está fixado em brew, embora o mesmo status deva representar o Arch. Usar backend yay (ou condicionar brew no macOS e yay no Arch). Evitar contar atualizações duplicadas por pacman e yay ao mesmo tempo.
   - Fonte: https://github.com/fabioluciano/tmux-powerkit/blob/main/src/plugins/packages.sh

9. **Inicialização do tmux/Smug**
   - O primeiro Ghostty pode iniciar Smug com Neovim, btop e nvtop, além de vários painéis de monitoramento do PowerKit. Isso é cômodo, mas pode iniciar mais trabalho do que necessário quando a intenção é somente abrir um terminal. Medir antes de remover; não foi medido impacto de CPU/GPU nesta auditoria.

10. **Controle de monitores externos**
    - ddcutil pode controlar brilho e entrada em telas compatíveis com DDC/CI, aproximando parte do BetterDisplay. Depende do monitor, DDC/CI habilitado e permissões/driver I²C.
    - Fonte: https://www.ddcutil.com/config/

## Ordem sugerida de trabalho

1. Instalar Compiz 0.9 sem Emerald, iniciar corretamente na sessão Xfce e verificar o decorador GTK.
2. Configurar o monitor principal em 165,08 Hz e corrigir a geometria lateral dos monitores na configuração do Compiz; conferir a sincronização das animações depois da mudança.
3. Corrigir atalhos duplicados e estabelecer um responsável pelo tiling.
4. Completar Vicinae, trocar Espanso para X11 e ajustar a integração do clipboard/sessões do tmux.
5. Testar NVDEC no mpv e NVENC no OBS; avaliar decodificação VA-API do Firefox apenas se aceitar o custo de sandbox documentado.

## Limites da auditoria

- A sessão examinada estava em X11; o estado de processos e telas pode mudar depois de reiniciar ou alterar configurações.
- A pesquisa AUR confirmou a família e o pacote do Compiz. Consultas AUR posteriores para Vicinae e Espanso X11 falharam por indisponibilidade de DNS no ambiente; portanto, não registrar nomes de pacotes Arch sem nova consulta yay.
- Não foram medidos frametimes, tearing, latência de entrada nem uso de CPU/GPU durante efeitos reais. Recomendações de otimização visual devem ser validadas após selecionar o modo de 165 Hz.
- Nenhum pacote foi instalado e nenhum arquivo do chezmoi foi modificado por esta auditoria. Alterações existentes no repositório foram mantidas intactas.

## Fontes NVIDIA e Xfce

- Manual NVIDIA 615.78.08 sobre suspensão: https://download.nvidia.com/XFree86/Linux-x86_64/615.78.08/README/powermanagement.html
- Código NVIDIA 615.78.08 para os parâmetros de suspensão: https://github.com/NVIDIA/open-gpu-kernel-modules/blob/615.78.08/kernel-open/nvidia/nv-reg.h
- Sincronização OpenGL/VBlank NVIDIA: https://download.nvidia.com/XFree86/Linux-x86_64/615.78.08/README/openglenvvariables.html
- Opções X da NVIDIA e pipeline de composição: https://download.nvidia.com/XFree86/Linux-x86_64/615.78.08/README/xconfigoptions.html
- Inicialização de sessão Xfce: https://github.com/xfce-mirror/xfce4-session/blob/master/xfce4-session/xfsm-manager.c
