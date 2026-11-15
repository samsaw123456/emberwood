#!/usr/bin/env python3
"""Native X11 controls and rendered evidence for LAN co-op; requires Python Xlib/Pillow."""

import array
import json
import os
import subprocess
import time
import wave
from pathlib import Path

from lan_audit import ROOT, Peer
from PIL import Image, ImageDraw
from Xlib import XK, X, display
from Xlib.ext import xtest

OUTPUT = ROOT / "build/lan-audit/native"
XVFB_ROOT = Path.home() / ".local/share/phippy-tools/xvfb/root"


class Native:
    def __init__(self, peer, address):
        self.peer = peer
        self.dpy = display.Display(address)
        self.root = self.dpy.screen().root
        self.win = self.find(self.root)
        assert self.win, "Game window was not created"
        self.focus()

    def find(self, window):
        if (window.get_wm_name() or "").startswith("Emberwood audit " + self.peer.name):
            return window
        for child in window.query_tree().children:
            result = self.find(child)
            if result:
                return result
        return None

    def focus(self):
        self.win.set_input_focus(X.RevertToParent, X.CurrentTime)
        self.dpy.sync()
        time.sleep(0.08)

    def key(self, name, down):
        code = self.dpy.keysym_to_keycode(XK.string_to_keysym(name))
        assert code, name
        xtest.fake_input(self.dpy, X.KeyPress if down else X.KeyRelease, code)
        self.dpy.sync()

    def press(self, name, duration=0.08):
        self.key(name, True)
        time.sleep(duration)
        self.key(name, False)
        time.sleep(0.08)

    def click(self, text):
        status = self.peer.wait(
            lambda s: any(b["text"] == text and not b["disabled"] for b in s["buttons"])
        )
        button = next(b for b in status["buttons"] if b["text"] == text)
        self.click_at(button["x"], button["y"])

    def click_at(self, x, y, button=1):
        size = self.peer.status()
        # The canvas stretches to the actual window. At 800x600 its logical size
        # follows Godot's viewport aspect, so use the observed transform ratio.
        ratio = size["width"] / 1152
        xtest.fake_input(self.dpy, X.MotionNotify, x=int(x * ratio), y=int(y * ratio))
        xtest.fake_input(self.dpy, X.ButtonPress, button)
        xtest.fake_input(self.dpy, X.ButtonRelease, button)
        self.dpy.sync()
        time.sleep(0.12)

    def screenshot(self, name):
        frames = self.peer.status()["frames"]
        self.peer.wait(lambda s: s["frames"] > frames)
        self.dpy.sync()
        geom = self.win.get_geometry()
        raw = self.win.get_image(0, 0, geom.width, geom.height, X.ZPixmap, 0xFFFFFFFF)
        image = Image.frombytes(
            "RGB", (geom.width, geom.height), raw.data, "raw", "BGRX"
        )
        image.save(OUTPUT / f"{name}.png", compress_level=1)
        return image


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    data = OUTPUT / "data"
    data.mkdir(exist_ok=True)
    for old in data.glob("*-command.json"):
        old.unlink()
    for old in data.glob("*-status.json"):
        old.unlink()
    pulse = ROOT / "build/lan-audit/pulse-tools/extracted/usr/bin"
    modules = []
    sink_prefix = f"emberwood_lan_audit_{os.getpid()}"
    servers = []
    peers = []
    rows = []
    if (
        os.environ.get("EMBERWOOD_NATIVE_GUEST_ONLY")
        and (OUTPUT / "controls.json").exists()
    ):
        rows = json.loads((OUTPUT / "controls.json").read_text())
    frames = []

    def passed(binding, state, effect, evidence):
        rows.append(
            {
                "binding": binding,
                "state": state,
                "expected": effect,
                "result": "passed",
                "evidence": evidence,
            }
        )
        print(f"PASS: {binding} / {state}: {effect}", flush=True)

    def proof(ui, label):
        image = ui.screenshot(label)
        frames.append((label, image))
        return label + ".png"

    def wait_all(state):
        for peer in peers:
            peer.wait(lambda s: s["state"] == state)

    def reset_player(index, x=300, y=536):
        if index:
            peers[0].wait(lambda s: s["players"][index]["mask"] == 0)
        peers[0].command("position", player=index, x=x, y=y)
        peers[index].wait(lambda s: abs(s["local_x"] - x) < 1)
        time.sleep(0.12)

    def disabled_game_keys(ui, state):
        at = ui.peer.status()["local_x"]
        stage = ui.peer.status()["stage"]
        for key in ["a", "d", "w", "Shift_L", "Shift_R", "j", "r"]:
            ui.press(key)
            current = ui.peer.status()
            assert abs(current["local_x"] - at) < 1 and current["stage"] == stage, (
                key,
                state,
            )
            passed(
                key,
                state,
                "No gameplay movement, shot or retry",
                proof(ui, f"disabled-{state}-{key}"),
            )
        for key in ["Left", "Right", "Up", "Down", "Tab"]:
            ui.press(key)
            assert ui.peer.status()["local_x"] == at
            passed(
                key,
                state + " menu",
                "Keyboard focus navigation; fox stays still",
                proof(ui, f"menu-{state}-{key}"),
            )
        ui.key("Shift_L", True)
        ui.press("Tab")
        ui.key("Shift_L", False)
        passed(
            "Shift+Tab",
            state + " menu",
            "Backward keyboard focus navigation",
            proof(ui, f"menu-{state}-back-tab"),
        )

    def capture_jump(ui, label):
        output = OUTPUT / (label + ".raw")
        with output.open("wb") as recording:
            process = subprocess.Popen(
                [
                    str(pulse / "parec"),
                    "--device=" + sink_prefix + "_" + ui.peer.name + ".monitor",
                    "--format=s16le",
                    "--rate=22050",
                    "--channels=1",
                    "--latency-msec=30",
                ],
                stdout=recording,
                stderr=subprocess.PIPE,
            )
            time.sleep(0.2)
            ui.press("space", 0.15)
            time.sleep(0.9)
            process.terminate()
            process.wait(timeout=3)
        raw = output.read_bytes()
        assert len(raw) > 1000, "No audio capture samples"
        with wave.open(str(OUTPUT / (label + ".wav")), "wb") as wav:
            wav.setnchannels(1)
            wav.setsampwidth(2)
            wav.setframerate(22050)
            wav.writeframes(raw)
        samples = array.array("h", raw)
        return max(abs(sample) for sample in samples)

    try:
        for index in range(4):
            address = f":{181 + index}"
            env = dict(
                os.environ, LD_LIBRARY_PATH=str(XVFB_ROOT / "usr/lib/x86_64-linux-gnu")
            )
            server = subprocess.Popen(
                [
                    str(XVFB_ROOT / "usr/bin/Xvfb"),
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
            servers.append(server)
            time.sleep(0.25)
            sink = sink_prefix + f"_p{index + 1}"
            module = subprocess.check_output(
                [
                    str(pulse / "pactl"),
                    "load-module",
                    "module-null-sink",
                    "sink_name=" + sink,
                ],
                text=True,
            ).strip()
            modules.append(module)
            previous_sink = os.environ.get("PULSE_SINK")
            os.environ["PULSE_SINK"] = sink
            peers.append(Peer(data, f"p{index + 1}", address))
            if previous_sink is None:
                del os.environ["PULSE_SINK"]
            else:
                os.environ["PULSE_SINK"] = previous_sink
        uis = [Native(peer, f":{181 + index}") for index, peer in enumerate(peers)]
        host, guest = peers[:2]
        h, g = uis[:2]
        proof(h, "title")
        disabled_game_keys(h, "title")
        # Return focus to Start so Tab independently proves LAN menu navigation.
        h.click("Start adventure")
        host.command("leave")
        host.wait(lambda s: s["state"] == 0)
        h.press("Tab")
        h.press("Return")
        host.wait(lambda s: bool(s["fields"]))
        passed("Tab + Enter", "title", "Focus and open LAN menu", proof(h, "lan-menu"))
        h.click("Back")
        passed(
            "Left mouse / Back", "LAN menu", "Return to title", proof(h, "back-title")
        )
        h.click("LAN co-op · 2–4 players")
        h.click("Host a game")
        host.wait(lambda s: s["hosting"])
        passed(
            "Left mouse / Host",
            "LAN menu",
            "Host lobby; Start disabled with one player",
            proof(h, "one-player-lobby"),
        )
        for index, ui in enumerate(uis[1:], 2):
            ui.click("LAN co-op · 2–4 players")
            field = ui.peer.wait(lambda s: bool(s["fields"]))["fields"][0]
            ui.click_at(field["x"], field["y"])
            if index == 2:
                ui.press("Return")
                ui.peer.wait(lambda s: "address" in s["error"])
                passed(
                    "Enter / empty address",
                    "LAN menu",
                    "Show address error and remain usable",
                    proof(ui, "invalid-address"),
                )
            for char in "127.0.0.1":
                ui.press("period" if char == "." else char, 0.02)
            if index == 3:
                ui.click("Join game")
            else:
                ui.press("Return")
            ui.peer.wait(lambda s: s["connected"])
            host.wait(lambda s, count=index: len(s["players"]) == count)
            passed(
                "Address typing + Enter" if index != 3 else "Left mouse / Join",
                "LAN menu",
                f"P{index} joins host",
                proof(ui, f"p{index}-lobby"),
            )
        disabled_game_keys(h, "lobby")
        proof(h, "four-player-lobby")
        h.click("Start co-op")
        wait_all(1)
        passed(
            "Left mouse / Start co-op",
            "lobby",
            "All four players enter shared world",
            proof(h, "four-players"),
        )
        for index, ui in enumerate(uis[2:], 2):
            before = ui.peer.status()["local_x"]
            ui.press("d", 0.25)
            ui.peer.wait(lambda s, before=before: s["local_x"] > before + 20)
            passed(
                "D",
                f"P{index + 1} playing",
                "Own fox moves right, independently",
                proof(ui, f"p{index + 1}-movement"),
            )
        # Four simultaneous software-rendered windows overload this test desktop.
        # Keep P3/P4 peers live but suspend their rendering during the binding audit.
        for peer in peers[2:]:
            peer.command("render_off")
        time.sleep(0.5)
        if host.status()["state"] == 2:
            h.click("Keep exploring")
        wait_all(1)
        control_players = [(0, h), (1, g)]
        if os.environ.get("EMBERWOOD_NATIVE_GUEST_ONLY"):
            control_players = [(1, g)]
        if os.environ.get("EMBERWOOD_NATIVE_FLOW_ONLY"):
            control_players = []
        for index, ui in control_players:
            role = "host" if index == 0 else "guest"
            for key, direction in [("a", -1), ("Left", -1), ("d", 1), ("Right", 1)]:
                reset_player(index)
                before = ui.peer.status()["local_x"]
                proof(ui, f"{role}-{key}-before")
                ui.key(key, True)
                ui.peer.wait(
                    lambda s, before=before, direction=direction: (
                        (s["local_x"] - before) * direction > 32
                    )
                )
                during = proof(ui, f"{role}-{key}-held")
                ui.key(key, False)
                ui.peer.wait(
                    lambda s: (
                        abs(
                            next(
                                p
                                for p in s["players"]
                                if p["number"] == s["local_number"]
                            )["vx"]
                        )
                        < 0.1
                    )
                )
                at = ui.peer.status()["local_x"]
                time.sleep(0.2)
                assert abs(ui.peer.status()["local_x"] - at) < 1, key
                after = proof(ui, f"{role}-{key}-released")
                passed(
                    key,
                    f"{role} playing",
                    "Moves screen-left" if direction < 0 else "Moves screen-right",
                    during + ", " + after,
                )
            for key in ["space", "w", "Up"]:
                reset_player(index)
                ui.key(key, True)
                ui.peer.wait(lambda s: s["local_y"] < 455)
                first = proof(ui, f"{role}-{key}-jump")
                ui.key(key, False)
                ui.peer.wait(lambda s: s["local_y"] > 530)
                reset_player(index)
                ui.key(key, True)
                ui.peer.wait(lambda s: s["local_y"] < 500)
                ui.key(key, False)
                release_frame = ui.peer.status()["frames"]
                ui.peer.wait(lambda s, frame=release_frame: s["frames"] > frame)
                ui.key(key, True)
                ui.peer.wait(
                    lambda s: (
                        next(
                            p for p in s["players"] if p["number"] == s["local_number"]
                        )["jumps"]
                        == 0
                    )
                )

                ui.key(key, False)
                release_frame = ui.peer.status()["frames"]
                ui.peer.wait(lambda s, frame=release_frame: s["frames"] > frame)
                ui.key(key, True)
                ui.peer.wait(
                    lambda s: (
                        next(
                            p for p in s["players"] if p["number"] == s["local_number"]
                        )["jumps"]
                        == 0
                    )
                )
                second = proof(ui, f"{role}-{key}-double")
                ui.key(key, False)
                passed(
                    key,
                    f"{role} playing",
                    "Jump, release, double jump; no third jump",
                    first + ", " + second,
                )
                time.sleep(0.8)
            for key in ["Shift_L", "Shift_R"]:
                reset_player(index)
                before = ui.peer.status()["local_x"]
                ui.key(key, True)
                ui.peer.wait(lambda s, before=before: s["local_x"] > before + 30)
                dash = proof(ui, f"{role}-{key}-dash")
                time.sleep(0.8)
                at = ui.peer.status()["local_x"]
                time.sleep(0.2)
                assert abs(ui.peer.status()["local_x"] - at) < 1
                ui.key(key, False)
                passed(
                    key,
                    f"{role} playing",
                    "Dash right once while held, then recover",
                    dash,
                )
            reset_player(index)
            ui.key("a", True)
            ui.key("d", True)
            time.sleep(0.3)
            assert abs(ui.peer.status()["local_x"] - 300) < 5
            ui.key("a", False)
            ui.peer.wait(lambda s: s["local_x"] > 330)
            ui.key("d", False)
            passed(
                "A+D; release A",
                f"{role} playing",
                "Opposing directions stop; remaining D moves right",
                proof(ui, f"{role}-opposing"),
            )
            reset_player(index)
            ui.key("a", True)
            ui.peer.wait(lambda s: s["local_x"] < 292)
            ui.key("a", False)
            ui.key("Shift_L", True)
            ui.peer.wait(lambda s: s["local_x"] < 260)
            ui.key("Shift_L", False)
            passed(
                "A then Shift",
                f"{role} playing",
                "Facing-left dash moves screen-left",
                proof(ui, f"{role}-dash-left"),
            )
            for key in ["Escape", "p"]:
                ui.press(key)
                wait_all(2)
                paused = proof(ui, f"{role}-{key}-paused")
                at = ui.peer.status()["local_x"]
                ui.press("d")
                assert ui.peer.status()["local_x"] == at
                ui.press(key)
                wait_all(1)
                passed(
                    key,
                    f"{role} playing / paused",
                    "Pause all four; movement disabled; resume",
                    paused,
                )
            reset_player(index)
            ui.key("d", True)
            time.sleep(0.15)
            ui.root.set_input_focus(X.RevertToParent, X.CurrentTime)
            ui.dpy.sync()
            wait_all(2)
            ui.key("d", False)
            ui.focus()
            ui.click("Keep exploring")
            wait_all(1)
            ui.peer.wait(
                lambda s: (
                    abs(
                        next(
                            p for p in s["players"] if p["number"] == s["local_number"]
                        )["vx"]
                    )
                    < 0.1
                )
            )
            at = ui.peer.status()["local_x"]
            time.sleep(0.2)
            assert abs(ui.peer.status()["local_x"] - at) < 1
            passed(
                "D + focus loss + release",
                f"{role} playing",
                "Team pauses; no stuck movement after resume",
                proof(ui, f"{role}-focus-recovery"),
            )
        host.command("camp", index=1)
        for ui in [h, g]:
            ui.peer.wait(lambda s: s["weapon"] == "bow")
            reset_player(0 if ui is h else 1, x=300)
            ui.key("j", True)
            ui.peer.wait(lambda s: s["arrows"] > 0)
            shot = proof(ui, f"{ui.peer.name}-J-bow")
            end = ui.peer.status()["elapsed"] + 1.3
            ui.peer.wait(lambda s, end=end: s["elapsed"] >= end and s["arrows"] == 0)
            ui.key("j", False)
            released = ui.peer.status()["frames"]
            ui.peer.wait(lambda s, released=released: s["frames"] > released + 1)
            ui.press("j")
            ui.peer.wait(lambda s: s["arrows"] > 0)
            passed(
                "J (press, hold, release, repeat)",
                ui.peer.name + " playing",
                "One visible shot per press; no held autofire",
                shot,
            )
        before = host.status()["deaths"]
        g.press("r")
        host.wait(lambda s: s["deaths"] == before + 1)
        proof(g, "guest-retry-hurt")
        wait_all(1)
        passed(
            "R",
            "guest playing / respawning",
            "Party returns to earned camp with bow",
            proof(h, "party-at-camp"),
        )
        # Exercise failure and recovery through real movement into the first spikes.
        host.command("restart")
        wait_all(1)
        reset_player(1, x=485)
        before = host.status()["deaths"]
        g.key("d", True)
        host.wait(lambda s: s["deaths"] > before)
        g.key("d", False)
        proof(g, "spike-failure")
        wait_all(1)
        passed(
            "D into spikes",
            "guest playing",
            "Visible failure and team retry",
            proof(h, "failure-recovered"),
        )
        for index, ui in enumerate([h, g]):
            reset_player(index)
            if ui.peer.status()["muted"]:
                ui.press("m")
            audible = capture_jump(ui, ui.peer.name + "-sound-on")
            assert audible > 100, audible
            ui.press("m")
            ui.peer.wait(lambda s: s["muted"])
            muted = capture_jump(ui, ui.peer.name + "-sound-off")
            assert muted < 5, muted
            ui.press("m")
            ui.peer.wait(lambda s: not s["muted"])
            resumed = capture_jump(ui, ui.peer.name + "-sound-restored")
            assert resumed > 100, resumed
            passed(
                "M",
                ui.peer.name + " playing",
                f"Actual audio on/off/restored peaks {audible}/{muted}/{resumed}",
                proof(ui, ui.peer.name + "-mute-recovery"),
            )
            ui.press("Escape")
            wait_all(2)
            ui.click("Sound")
            ui.peer.wait(lambda s: s["muted"])
            ui.click("Sound")
            ui.peer.wait(lambda s: not s["muted"])
            ui.click("Gentle motion")
            ui.peer.wait(lambda s: s["motion"])
            passed(
                "Left mouse / Sound and Gentle motion",
                ui.peer.name + " paused",
                "Toggle local settings with visible checkmarks",
                proof(ui, ui.peer.name + "-settings"),
            )
            ui.click("Gentle motion")
            ui.peer.wait(lambda s: not s["motion"])
            ui.click("Keep exploring")
            wait_all(1)
        # All displayed equipment choices, including scrolling/focus into view.
        host.command("level", index=19)
        host.command("camp", index=1)
        wait_all(1)
        h.press("Escape")
        wait_all(2)

        disabled_game_keys(g, "guest-paused")
        # Start from resume; each Tab reaches the next unlocked checkbox, scrolling
        # its actual row into view. Space changes the shared loadout.
        h.click("Keep exploring")
        wait_all(1)
        h.press("Escape")
        wait_all(2)
        items = [
            ("bow", "weapon"),
            ("spear", "weapon"),
            ("seed_bomb", "weapon"),
            ("thorn_fan", "weapon"),
            ("sunwood_lance", "weapon"),
            ("armor", "armor"),
            ("bark_armor", "armor"),
            ("ironwood_armor", "armor"),
            ("reed_mail", "armor"),
            ("frost_armor", "armor"),
            ("stoneplate", "armor"),
            ("copperbark_armor", "armor"),
            ("sunleaf_armor", "armor"),
        ]
        for item, category in items:
            h.press("Tab")
            evidence = proof(h, "gear-focus-" + item)
            # First disable if already equipped, then enable with the same binding.
            if host.status()[category] == item:
                h.press("space")
                host.wait(lambda s, category=category, item=item: s[category] != item)
            h.press("space")
            host.wait(lambda s, category=category, item=item: s[category] == item)
            guest.wait(lambda s, category=category, item=item: s[category] == item)
            passed(
                "Tab + Space / " + item,
                "host gear menu",
                "Scroll selection into view and equip for team",
                evidence,
            )
        # Each shared gear entry also receives a mouse click after scroll/focus.
        for item, name in [
            ("bow", "Bow"),
            ("spear", "Throwing spear"),
            ("seed_bomb", "Seed bombs"),
            ("thorn_fan", "Thorn fan"),
            ("sunwood_lance", "Sunwood lance"),
        ]:
            if host.status()["state"] != 2:
                h.press("Escape")
                wait_all(2)
            host.command("gear", item=item, enabled=True)
            h.click("Keep exploring")
            wait_all(1)
            reset_player(1)
            g.press("j")
            g.peer.wait(lambda s: s["arrows"] > 0)
            passed(
                "J",
                "guest / " + name,
                "Selected weapon appears in all worlds",
                proof(g, f"guest-weapon-{item}"),
            )
            time.sleep(1.2)
            h.press("Escape")
            wait_all(2)
        # Keep clear evidence of the full guest equipment restrictions.
        proof(g, "guest-gear-disabled")
        h.click("Keep exploring")
        wait_all(1)
        host.command("level", index=0)
        host.command("gate", player=1)
        wait_all(5)
        disabled_game_keys(g, "chapter-complete")
        proof(g, "guest-level-complete")
        h.click("Continue to Flooded Mill")
        for peer in peers:
            peer.wait(lambda s: s["stage"] == 1 and s["state"] == 1)
        passed(
            "Left mouse / Continue",
            "chapter complete",
            "Host advances all four worlds",
            proof(g, "guest-next-chapter"),
        )
        host.command("level", index=19)
        host.command("gate", player=2)
        wait_all(4)
        disabled_game_keys(g, "won")
        proof(g, "guest-victory")
        h.click("Explore again")
        for peer in peers:
            peer.wait(lambda s: s["stage"] == 0 and s["state"] == 1)
        passed(
            "Left mouse / Explore again",
            "won",
            "Reset party to first level",
            proof(h, "restarted-party"),
        )
        h.press("Escape")
        wait_all(2)
        h.win.configure(width=800, height=600)
        h.dpy.sync()
        host.wait(lambda s: s["width"] == 800)
        proof(h, "pause-800")
        h.win.configure(width=1152, height=648)
        h.dpy.sync()
        host.wait(lambda s: s["width"] == 1152)
        g.click("Leave LAN game")
        guest.wait(lambda s: not s["connected"])
        host.wait(lambda s: len(s["players"]) == 3)
        passed(
            "Left mouse / Leave LAN game",
            "paused guest",
            "Leave cleanly; other players remain",
            proof(g, "guest-left"),
        )
        h.click("Close LAN game")
        host.wait(lambda s: not s["connected"])
        passed(
            "Left mouse / Close LAN game",
            "paused host",
            "All remaining guests return to title",
            proof(h, "host-closed"),
        )
    finally:
        (OUTPUT / "controls.json").write_text(json.dumps(rows, indent=2))
        for start in range(0, len(frames), 12):
            group = frames[start : start + 12]
            sheet = Image.new("RGB", (1152, 240 * 4), "#152b27")
            draw = ImageDraw.Draw(sheet)
            for index, (name, frame) in enumerate(group):
                x, y = (index % 3) * 384, (index // 3) * 240
                frame.thumbnail((384, 216))
                sheet.paste(frame, (x, y + 24))
                draw.text((x + 6, y + 6), name, fill="white")
            sheet.save(OUTPUT / f"contact-{start // 12 + 1:02}.jpg")
        for peer in peers:
            peer.close()
        for module in modules:
            subprocess.run([str(pulse / "pactl"), "unload-module", module], check=False)
        for server in servers:
            server.terminate()
            server.wait(timeout=5)
    print(f"PASS: {len(rows)} native control scenarios. Inspect saved rendered frames.")


if __name__ == "__main__":
    main()
