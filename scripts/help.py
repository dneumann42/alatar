#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["tk"]
# ///

from dataclasses import dataclass
import atexit
import os
import shlex
import tkinter as tk
from tkinter import ttk

def read_lines(path: str):
    with open(path, "r") as f:
        return [line for line in f.readlines()]

def read_mod_binding(path: str) -> str:
    try:
        with open(path, "r") as f:
            for line in f:
                stripped = line.strip()
                if stripped.startswith("set $mod "):
                    parts = shlex.split(stripped)
                    if len(parts) >= 3:
                        return parts[2]
    except FileNotFoundError:
        return "unknown"
    return "unknown"

def friendly_mod_name(mod: str) -> str:
    names = {
        "Mod4": "Super",
        "Mod1": "Alt",
        "Mod3": "Mod3",
        "Mod2": "Mod2",
        "Control": "Ctrl",
        "Shift": "Shift",
    }
    return names.get(mod, mod)

config_path = os.path.expanduser("~/.config/sway/config")
mod_binding = read_mod_binding(config_path)
mod_friendly = friendly_mod_name(mod_binding)
keybindings = os.path.expanduser("~/.config/sway/keybindings.conf")    
lines = list(read_lines(keybindings))

lock_path = "/tmp/alatar-help.lock"
try:
    lock_fd = os.open(lock_path, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
except FileExistsError:
    raise SystemExit(0)
else:
    os.write(lock_fd, str(os.getpid()).encode("ascii"))
    os.close(lock_fd)

def cleanup_lock() -> None:
    try:
        os.unlink(lock_path)
    except FileNotFoundError:
        pass

atexit.register(cleanup_lock)

@dataclass
class Binding:
    description: str
    binding: str
    command: str

bindings: list[Binding] = []
    
line_index = 0
def at_eof():
    return line_index >= len(lines)

while not at_eof():
    line = lines[line_index]
    line_index += 1
    if not line.startswith("#"):
        continue
    def is_blank(l: str) -> bool:
        return l.isspace()
    while not at_eof() and is_blank(lines[line_index]):
        line_index += 1
    if at_eof() or not lines[line_index].lstrip().startswith("bindsym"):
        continue
    while not at_eof() and not is_blank(lines[line_index]) and not lines[line_index].lstrip().startswith('#'):
        raw_line = lines[line_index].strip()
        line_index += 1
        tokens = shlex.split(raw_line)
        if not tokens or tokens[0] != "bindsym":
            continue
        idx = 1
        while idx < len(tokens) and tokens[idx].startswith("--"):
            idx += 1
        if idx >= len(tokens):
            continue
        key = tokens[idx]
        command_tokens = tokens[idx + 1 :]
        command = shlex.join(command_tokens) if command_tokens else ""
        bindings.append(Binding(
            description=line[1:].strip(),
            binding=key,
            command=command,
        ))

root = tk.Tk()
root.title(" DEV ")
root.geometry("900x600")
_ = root.bind("<Escape>", lambda _event: root.destroy())
_ = root.bind("q", lambda _event: root.destroy())

style = ttk.Style()
style.theme_use("clam")
style.configure("TFrame", background="#1e1e1e")
style.configure("TLabel", background="#1e1e1e", foreground="#e6e6e6")
style.configure("Treeview",
                background="#1e1e1e",
                fieldbackground="#1e1e1e",
                foreground="#e6e6e6")
style.configure("Treeview.Heading",
                background="#2a2a2a",
                foreground="#e6e6e6")
style.map("Treeview",
          background=[("selected", "#3a3a3a"), ("active", "#252525")],
          foreground=[("selected", "#ffffff"), ("active", "#e6e6e6")])
style.map("Treeview.Heading",
          background=[("active", "#333333")],
          foreground=[("active", "#e6e6e6")])
style.configure("TButton", background="#2a2a2a", foreground="#e6e6e6")

frm = ttk.Frame(root, padding=10)
frm.grid(row=0, column=0, sticky="nsew")
_ = root.columnconfigure(0, weight=1)
_ = root.rowconfigure(0, weight=1)

mod_label = ttk.Label(frm, text=f"$mod = {mod_friendly} ({mod_binding})")
mod_label.grid(row=0, column=0, sticky="w", pady=(0, 6))

columns = ("description", "binding", "command")
tree = ttk.Treeview(frm, columns=columns, show="headings")
tree.heading("description", text="Description")
tree.heading("binding", text="Binding")
tree.heading("command", text="Executes")
_ = tree.column("description", width=280, anchor="w")
_ = tree.column("binding", width=160, anchor="w")
_ = tree.column("command", width=520, anchor="w")

scroll_y = ttk.Scrollbar(frm, orient="vertical", command=tree.yview)  # pyright: ignore[reportUnknownMemberType]
scroll_x = ttk.Scrollbar(frm, orient="horizontal", command=tree.xview)  # pyright: ignore[reportUnknownMemberType]
_ = tree.configure(yscrollcommand=scroll_y.set, xscrollcommand=scroll_x.set)

tree.grid(row=1, column=0, sticky="nsew")
scroll_y.grid(row=1, column=1, sticky="ns")
scroll_x.grid(row=2, column=0, sticky="ew")

_ = frm.columnconfigure(0, weight=1)
_ = frm.rowconfigure(1, weight=1)

for entry in bindings:
    _ = tree.insert("", "end", values=(entry.description, entry.binding, entry.command))

btn_row = ttk.Frame(frm)
btn_row.grid(row=3, column=0, columnspan=2, pady=(8, 0), sticky="e")
ttk.Button(btn_row, text="Quit", command=root.destroy).grid(row=0, column=0)

root.mainloop()
