# roEZ

**RoE Made Easy: A GUI-based Records of Eminence Manager for Ashita v4**

`roEZ` is a streamlined Lua addon for Final Fantasy XI, built for Ashita v4, that provides a modern, intuitive interface to manage **Records of Eminence (RoE)** objectives. Easily create, apply, and save profiles of objectives with a focus on speed, customization, and clarity.

---

## 🌟 Features

* 🧩 **Profile Manager**

  * Save and load named sets of objectives (e.g., `default`, `cp`, `crafting`)
  * Easily toggle between RoE sets using a slick multi-pane GUI

* 🔒 **Objective Locking**

  * Prevent important objectives from being overwritten

* 👁️ **Preview Changes**

  * View exactly which objectives will be added or removed before applying

* 🧠 **Progress Awareness**

  * View current progress bars for all active objectives

* 🧼 **Clean UI**

  * Minimalist layout with Ashita ImGui styling and full mouse interaction

---

![Single Objectives](roez-single.png)

## 🔧 Installation

1. **Clone or download** this repo into your Ashita `addons` folder:

   ```bash
   git clone https://github.com/commandobill/roEZ.git
   ```

2. **Launch Ashita**, log in, and load the addon:

   ```
   /addon load roez
   ```

---

## 🚀 Usage

* Open the interface:

  ```
  /roez
  ```

* In the UI:

  * **Left Column**: Master list of all RoE objectives
  * **Middle Column**: Locked objectives (protected from auto-removal)
  * **Right Column**: Profile queue for saving/applying

* Tabs:

  * `Profiles`: Save/load sets of objectives
  * `Single Objectives`: Manually toggle RoEs with full progress display

---

## 📂 File Overview

| File                 | Purpose                                     |
| -------------------- | ------------------------------------------- |
| `roEZ.lua`           | Main entry point / state tracking / startup |
| `ui.lua`             | Handles full GUI rendering logic            |
| `profiles.lua`       | Persistent storage for profile + lock data  |
| `packets.lua`        | Sends and receives RoE packets              |
| `modal.lua`          | Displays preview confirmation modals        |
| `objective_list.lua` | Shared UI widget for list columns           |
| `set.lua`            | Lightweight Set utility object              |
| `utils.lua`          | General-purpose helpers                     |
| `styles.lua`         | Applies custom ImGui color theme            |
| `log.lua`            | Pretty-prints messages to Ashita chat       |

---

## 🧪 Known Limitations

* Currently supports only 30 objectives (FFXI limit)
* No hotkeys or automation features (GUI-only)

---

## 📜 License

This project is licensed under the MIT License.

---

## 🙌 Acknowledgements

Created by **Commandobill** with love for the FFXI community. Inspired by the need to make RoE management less tedious and more efficient.

Contributions and feature suggestions welcome!

---

## 📎 Links

* GitHub: [github.com/commandobill/roEZ](https://github.com/commandobill/roEZ)
* Ashita: [https://ashitaxi.com/](https://ashitaxi.com/)
