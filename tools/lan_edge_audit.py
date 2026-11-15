#!/usr/bin/env python3
"""Additional native menu, retry-state, equipment and guest guardian checks."""

import json
import os
import subprocess
import time

import lan_native_audit as native
from lan_audit import ROOT, Peer


def main():
    output = ROOT / "build/lan-audit/edges"
    output.mkdir(parents=True, exist_ok=True)
    native.OUTPUT = output
    for old in output.glob("*-command.json"):
        old.unlink()
    for old in output.glob("*-status.json"):
        old.unlink()
    servers, peers, rows = [], [], []

    def passed(ui, key, state, effect):
        name = f"edge-{len(rows):03}"
        ui.screenshot(name)
        rows.append(
            {
                "binding": key,
                "state": state,
                "result": "passed",
                "expected": effect,
                "evidence": name + ".png",
            }
        )
        print("PASS:", key, state, effect, flush=True)

    def mute_in(ui, state):
        before = ui.peer.status()["muted"]
        ui.press("m")
        ui.peer.wait(lambda s: s["muted"] != before)
        passed(ui, "M", state, "Local sound setting changes with visible feedback")
        ui.press("m")
        ui.peer.wait(lambda s: s["muted"] == before)

    def all_state(state):
        for peer in peers:
            peer.wait(lambda s: s["state"] == state)

    def focus(ui, text):
        for _ in range(35):
            if ui.peer.status()["focus_text"] == text:
                return
            before = ui.peer.status()["focus"]
            ui.press("Tab")
            ui.peer.wait(lambda s, before=before: s["focus"] != before)
        raise AssertionError("Could not focus " + text)

    try:
        for index in range(2):
            address = f":{201 + index}"
            env = dict(
                os.environ,
                LD_LIBRARY_PATH=str(native.XVFB_ROOT / "usr/lib/x86_64-linux-gnu"),
            )
            servers.append(
                subprocess.Popen(
                    [
                        str(native.XVFB_ROOT / "usr/bin/Xvfb"),
                        address,
                        "-screen",
                        "0",
                        "1152x648x24",
                        "-nolisten",
                        "tcp",
                    ],
                    env=env,
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
            )
            time.sleep(0.2)
            peers.append(Peer(output, f"edge{index}", address))
        h, g = [
            native.Native(peer, f":{201 + index}") for index, peer in enumerate(peers)
        ]
        host, guest = peers
        for key in ["Escape", "p"]:
            h.press(key)
            assert host.status()["state"] == 0
            passed(h, key, "title", "Remain on title")
        h.press("KP_Enter")
        host.wait(lambda s: s["state"] == 1)
        passed(h, "Keypad Enter", "solo title", "Start adventure")
        h.press("Escape")
        host.wait(lambda s: s["state"] == 2)
        h.press("space")
        host.wait(lambda s: s["state"] == 1)
        passed(h, "Space", "solo pause", "Activate Keep exploring")
        h.click("Ⅱ")
        host.wait(lambda s: s["state"] == 2)
        h.press("Return")
        host.wait(lambda s: s["state"] == 1)
        passed(
            h, "Left mouse / pause, Enter / resume", "solo playing", "Pause and resume"
        )
        host.command("leave")
        h.click("LAN co-op · 2–4 players")
        host.wait(lambda s: bool(s["fields"]))
        for key in ["Escape", "p", "j", "r"]:
            h.press(key)
            assert host.status()["state"] == 0
            passed(h, key, "LAN form", "No gameplay action")
        field = host.status()["fields"][0]
        h.click_at(field["x"], field["y"])
        for key in "123":
            h.press(key)
        host.wait(lambda s: s["fields"][0]["text"] == "123")
        h.press("BackSpace")
        host.wait(lambda s: s["fields"][0]["text"] == "12")
        h.press("Home")
        h.press("Delete")
        host.wait(lambda s: s["fields"][0]["text"] == "2")
        h.press("End")
        h.press("3")
        host.wait(lambda s: s["fields"][0]["text"] == "23")
        h.key("Control_L", True)
        h.press("a")
        h.key("Control_L", False)
        for char in "127.0.0.2":
            h.press("period" if char == "." else char)
        host.wait(lambda s: s["fields"][0]["text"] == "127.0.0.2")
        passed(
            h,
            "Digits, period, Backspace, Delete, Home, End, Ctrl+A",
            "address field",
            "Text edits match displayed address",
        )
        h.click("Join game")
        host.wait(lambda s: s["connecting"])
        host.command("hold_connection")
        for key in [
            "a",
            "d",
            "w",
            "Up",
            "Left",
            "Right",
            "Shift_L",
            "Shift_R",
            "j",
            "r",
            "Escape",
            "p",
        ]:
            h.press(key)
            assert host.status()["state"] == 0
            passed(h, key, "connecting", "No gameplay or accidental join")
            if not host.status()["connecting"]:
                break
        if host.status()["connecting"]:
            h.click("Cancel")
        else:
            h.click("LAN co-op · 2–4 players")
            host.command("join", address="127.0.0.2")
            h.click("Cancel")
        host.wait(lambda s: not s["connecting"])
        passed(h, "Left mouse / Cancel", "connecting", "Cancel returns to title")
        h.click("LAN co-op · 2–4 players")
        h.click("Host a game")
        host.wait(lambda s: s["hosting"])
        for key in ["Escape", "p"]:
            h.press(key)
            assert host.status()["lobby"]
            passed(h, key, "lobby", "Remain in lobby")
        h.press("space")
        host.wait(lambda s: not s["connected"])
        passed(
            h, "Space / Leave lobby", "one-player lobby", "Leave lobby and release port"
        )
        host.command("host")
        guest.command("join")
        host.wait(lambda s: len(s["players"]) == 2)
        h.press("Return")
        all_state(1)
        passed(h, "Enter / Start co-op", "two-player lobby", "Both players begin")
        for ui in [h, g]:
            for keys in [("Left", "Right"), ("d", "space"), ("d", "Shift_L")]:
                player = 0 if ui is h else 1
                host.command("position", player=player, x=300, y=536)
                ui.peer.wait(lambda s: abs(s["local_x"] - 300) < 1)
                for key in keys:
                    ui.key(key, True)
                if keys[0] == "Left":
                    time.sleep(0.3)
                    assert abs(ui.peer.status()["local_x"] - 300) < 5
                    ui.key("Left", False)
                    ui.peer.wait(lambda s: s["local_x"] > 325)
                else:
                    ui.peer.wait(lambda s: s["local_x"] > 325)
                for key in keys:
                    ui.key(key, False)
                passed(
                    ui,
                    "+".join(keys),
                    ui.peer.name + " playing",
                    "Combined input and release produce expected movement",
                )
        # Extend only the test fixture's retry timer to audit every disabled binding.
        before = host.status()["deaths"]
        h.press("r")
        host.wait(lambda s: s["state"] == 3)
        host.command("hold_respawn")
        passed(h, "R", "host playing", "Team enters retry")
        for key in [
            "a",
            "d",
            "Left",
            "Right",
            "space",
            "w",
            "Up",
            "Shift_L",
            "Shift_R",
            "j",
            "r",
        ]:
            at = host.status()["local_x"]
            h.press(key)
            assert host.status()["state"] == 3 and host.status()["local_x"] == at
            assert host.status()["deaths"] == before + 1
            passed(h, key, "retry animation", "No movement, shot, extra death or jump")
        for key in ["Escape", "p"]:
            g.press(key)
            all_state(2)
            g.press(key)
            all_state(3)
            passed(g, key, "retry / paused", "Pause and resume retry on every peer")
        g.key("space", True)
        host.command("finish_respawn")
        all_state(1)
        time.sleep(0.3)
        assert guest.status()["local_y"] > 530
        g.key("space", False)
        passed(
            g,
            "Held Space across retry",
            "guest retry / playing",
            "Release required before new jump",
        )
        host.command("level", index=19)
        host.command("camp", index=1)
        h.press("Escape")
        all_state(2)
        for name in [
            "Bow",
            "Throwing spear",
            "Seed bombs",
            "Thorn fan",
            "Sunwood lance",
            "Leaf armor",
            "Bark armor",
            "Ironwood armor",
            "Reed mail",
            "Frost armor",
            "Stoneplate",
            "Copperbark armor",
            "Sunleaf armor",
        ]:
            focus(h, name)
            before = next(
                b["pressed"] for b in host.status()["buttons"] if b["text"] == name
            )
            h.click(name)
            host.wait(
                lambda s, name=name, before=before: (
                    next(b["pressed"] for b in s["buttons"] if b["text"] == name)
                    != before
                )
            )
            passed(
                h, "Left mouse / " + name, "host equipment", "Toggle selected team item"
            )
        for button in [4, 5]:
            h.click_at(800, 390, button)
            passed(
                h,
                "Wheel up" if button == 4 else "Wheel down",
                "equipment",
                "Scroll armor choices",
            )
        h.click("Keep exploring")
        all_state(1)
        host.command("arena")
        guest.wait(lambda s: s["boss_health"] == 3)
        for health in [3, 2, 1]:
            current = guest.wait(
                lambda s, health=health: (
                    s["boss_phase"] == "rest" and s["boss_health"] == health
                ),
                timeout=20,
            )
            host.command("position", player=1, x=current["boss_x"] - 150, y=536)
            guest.wait(lambda s, x=current["boss_x"]: abs(s["local_x"] - (x - 150)) < 4)
            g.key("d", True)
            guest.wait(lambda s, x=current["boss_x"]: s["local_x"] > x - 145)
            g.key("d", False)
            g.press("j")
            guest.wait(lambda s, health=health: s["boss_health"] == health - 1)
            passed(
                g,
                "J against guardian",
                "guest boss rest",
                f"Guardian loses health from {health} to {health - 1}",
            )
        host.wait(lambda s: s["boss_defeated"])
        passed(
            g, "Guest boss fight", "playing", "Shared guardian victory and open gate"
        )
        h.press("Escape")
        all_state(2)
        for ui in [h, g]:
            mute_in(ui, ui.peer.name + " paused")
        h.click("Keep exploring")
        all_state(1)
        h.press("r")
        host.wait(lambda s: s["state"] == 3)
        host.command("hold_respawn")
        all_state(3)
        for ui in [h, g]:
            mute_in(ui, ui.peer.name + " retry")
        host.command("finish_respawn")
        all_state(1)
        host.command("gate", player=1)
        all_state(5)
        for ui in [h, g]:
            mute_in(ui, ui.peer.name + " chapter complete")
            for key in ["Escape", "p"]:
                ui.press(key)
                all_state(5)
                passed(ui, key, "chapter complete", "Results stay open")
        next_chapter = next(
            b["text"]
            for b in host.status()["buttons"]
            if b["text"].startswith("Continue to")
        )
        h.click(next_chapter)
        all_state(1)
        h.press("Escape")
        all_state(2)
        h.click("Restart all chapters")
        host.wait(lambda s: s["stage"] == 0 and s["state"] == 1)
        guest.wait(lambda s: s["stage"] == 0 and s["state"] == 1)
        passed(
            h,
            "Left mouse / Restart all chapters",
            "host pause",
            "Both players restart at chapter one",
        )
        host.command("level", index=19)
        host.command("gate", player=1)
        all_state(4)
        for ui in [h, g]:
            mute_in(ui, ui.peer.name + " won")
            for key in ["Escape", "p"]:
                ui.press(key)
                all_state(4)
                passed(ui, key, "won", "Results stay open")
        g.click("Leave LAN game")
        guest.wait(lambda s: not s["connected"] and s["state"] == 0)
        passed(g, "Left mouse / Leave LAN game", "guest won", "Return to title")
        h.click("Close LAN game")
        host.wait(lambda s: not s["connected"] and s["state"] == 0)
        passed(
            h,
            "Left mouse / Close LAN game",
            "host won",
            "Close session and return to title",
        )
        mute_in(h, "title")
        h.click("LAN co-op · 2–4 players")
        mute_in(h, "LAN form")
        h.click("Host a game")
        host.wait(lambda s: s["lobby"])
        mute_in(h, "lobby")
        h.click("Leave lobby")
        host.wait(lambda s: not s["connected"])
        host.command("join", address="127.0.0.2")
        host.wait(lambda s: s["connecting"])
        host.command("hold_connection")
        mute_in(h, "connecting")
        h.click("Cancel")
        host.wait(lambda s: not s["connecting"])
        for label, field in [("Sound", "muted"), ("Gentle motion", "motion")]:
            before = host.status()[field]
            h.click(label)
            host.wait(lambda s, field=field, before=before: s[field] != before)
            passed(h, "Left mouse / " + label, "title", "Visible local setting toggles")
            h.click(label)
            host.wait(lambda s, field=field, before=before: s[field] == before)
        h.click("Start adventure")
        host.wait(lambda s: s["state"] == 1)
        passed(h, "Left mouse / Start adventure", "title", "Solo adventure starts")
    finally:
        (output / "controls.json").write_text(json.dumps(rows, indent=2))
        for peer in peers:
            peer.close()
        for server in servers:
            server.terminate()
            server.wait(timeout=5)
    print(f"PASS: {len(rows)} additional native checks")


if __name__ == "__main__":
    main()
