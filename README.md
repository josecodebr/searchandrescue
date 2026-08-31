# 🚁 Modpack Search and Rescue & Factory Mine

This modpack adds vehicle manufacturing and complex Search and Rescue (SAR) missions to Luanti / Minetest. Players can construct, pilot, and operate tactical rescue helicopters equipped with towing ropes, specialized cameras, and rescue tools to locate and retrieve stranded vehicles in challenging terrain.

---
![plot](https://github.com/josecodebr/searchandrescue/blob/main/screenshot.png)
## 🚨 Overview & Features

* 🛠️ **Vehicle Manufacturing:** Build and automate your fleet using the Factory Mine system.
* 🚁 **Advanced Rescue Helicopter:** Based on the `Desour/helicopter` physics core, enhanced with full 3D vector calculations (`matrix.lua`) for realistic roll and pitch maneuvers.
* 🪢 **Towing & Recovery:** Deploy long rescue ropes directly from the helicopter to tow lost or stranded vehicles back to safety.
* 📹 **Multi-Camera Angles:** Switch between **5 distinct camera views** for precise situational awareness during recovery operations.
* 💡 **Tactical Miner Light:** Equip dynamic hand lights to illuminate dark areas temporarily during ground search operations.

---

## 📖 Guia de Operação e Gameplay

### 1. Centro de Desenvolvimento & Produção (Factory Mine)
> **Nota de Servidor:** No momento, a **Fábrica de Veículos** (`factory_mine:factory`) está disponível no **Modo Criativo** ou via comando de administração (`/giveme factory_mine:factory`) para garantir a estabilidade do servidor.

1. Posicione o nó da **Fábrica de Veículos** no chão.
2. A estrutura ativará automaticamente **4 luminárias industriais de canto** e convocará o **Robô Operário** para supervisionar a área.
3. Abra a interface da fábrica (botão direito), insira o item de montagem (ex: `searchandrescue:heli`) no slot de **Entrada**.
4. O *Node Timer* processará o item e fará o **spawn automático do Helicóptero** sobre a plataforma, atualizando o contador *"Total Produzido"*.

---

### 2. Pilotagem e Operação do Helicóptero

#### Embarque, Desembarque e Interface
* **Entrar no Veículo:** Aproxime-se do helicóptero e clique com o **botão direito**.
* **Interface de Controle (Formspec):** Ao entrar ou clicar com o botão direito no helicóptero, uma interface será exibida com as opções:
  * ❌ **Close:** Fecha o painel de interface.
  * 🚪 **Exit / Desembarque:** Sai do veículo (também acessível via teclas **`E`** ou **`F`**).
  * 📹 **Cam Set:** Alterna entre as **5 câmeras disponíveis** para facilitar manobras e resgates.
  * 🛠️ **Tools:** Abre as ferramentas táticas de resgate.

#### Controles de Voo
* **Subir / Decolar:** Tecla de Pulo (`Espaço`)
* **Descer / Pousar:** Tecla de Agachar (`Shift`)
* **Acelerar / Inclinar para Frente:** Tecla Ir para Frente (`W`)
* **Girar / Direção:** Teclas Esquerda / Direita (`A` / `D`)

#### Operação de Resgate (Towing System)
* Utilize a **corda longa de resgate** integrada ao helicóptero para prender e rebocar veículos encontrados no mapa de volta à base.

---

### 3. Manutenção e Remoção

* **Robô Operário:** Atua como unidade fixa da fábrica, sendo imune a socos ou ataques dos jogadores.
* **Desmontagem da Fábrica:** Esvazie o inventário da fábrica antes de quebrá-la. A remoção do bloco central limpa automaticamente o robô e as luzes periféricas do mapa.
* **Recolher Helicóptero:** Para recolher um helicóptero de volta ao inventário em forma de item, certifique-se de estar fora do veículo e dê um soco (*Punch*) nele.
---

## 📜 Credits & Codebase

This modpack utilizes and patches code from the [Desour/helicopter](https://github.com/Desour/helicopter) project, maintaining backwards compatibility and continuously improving vehicle interaction mechanics.

---

## ❗ Attention & Server Notice

> **Mod under active development.** It may contain minor bugs.  
> Please test and evaluate the mod locally before deploying it to production servers. Any decision to use this mod on a live server is the sole responsibility of the server administrator.
