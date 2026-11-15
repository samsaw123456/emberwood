#!/usr/bin/env python3
"""Exercise independent Emberwood processes with real ENet sockets and isolated saves."""

import argparse
import json
import os
import subprocess
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class Peer:
    def __init__(self, directory, name, display=None):
        self.directory = Path(directory)
        self.name = name
        self.sequence = 0
        self.log = (self.directory / f"{name}.log").open("w")
        env = dict(
            os.environ,
            XDG_DATA_HOME=str(directory),
            EMBERWOOD_TEST_DATA_DIR=str(directory),
            EMBERWOOD_TEST_PEER=name,
        )
        arguments = [str(ROOT / "emberwood"), "--script", "res://tests/lan_peer.gd"]
        if os.environ.get("EMBERWOOD_TEST_APP_BIN"):
            arguments = [
                os.environ["EMBERWOOD_TEST_APP_BIN"],
                "--main-pack",
                os.environ["EMBERWOOD_TEST_PACK"],
                "--script",
                str(ROOT / "tests/lan_peer.gd"),
            ]
        if display:
            env["DISPLAY"] = display
            env["XMODIFIERS"] = "@im=none"
            env["LANG"] = "C.UTF-8"
            env["LP_NUM_THREADS"] = "2"
            arguments += [
                "--display-driver",
                "x11",
                "--resolution",
                "1152x648",
                "--position",
                "0,0",
                "--max-fps",
                "60",
            ]
        else:
            arguments += ["--headless"]
        self.process = subprocess.Popen(
            arguments, cwd=ROOT, env=env, stdout=self.log, stderr=subprocess.STDOUT
        )
        self.wait(lambda s: s["frames"] > 2)

    def status(self):
        path = self.directory / f"{self.name}-status.json"
        return json.loads(path.read_text()) if path.exists() else {}

    def wait(self, condition, timeout=12):
        end = time.monotonic() + timeout
        last = {}
        while time.monotonic() < end:
            last = self.status()
            if last and condition(last):
                return last
            if self.process.poll() is not None:
                raise AssertionError(
                    f"{self.name} exited: {(self.directory / (self.name + '.log')).read_text()[-3000:]}"
                )
            time.sleep(0.025)
        raise AssertionError(f"{self.name}: condition timed out; {last}")

    def command(self, op, **values):
        self.sequence += 1
        command = dict(id=self.sequence, op=op, **values)
        path = self.directory / f"{self.name}-command.json"
        temporary = path.with_suffix(".tmp")
        temporary.write_text(json.dumps(command))
        temporary.replace(path)
        return self.wait(lambda s: s["command"] == self.sequence)

    def close(self):
        if self.process.poll() is None:
            self.process.terminate()
            try:
                self.process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.process.kill()
                self.process.wait()
        self.log.close()


def run(directory):
    peers = []
    checks = []

    def check(name, condition=True):
        assert condition, name
        checks.append(name)
        print("PASS:", name, flush=True)

    def launch(name):
        peer = Peer(directory, name)
        peers.append(peer)
        return peer

    def synced(field, expected):
        for player in peers[:4]:
            player.wait(lambda s: s[field] == expected)

    try:
        host = launch("host")
        host.command("host")
        host.command("begin")
        check("Host cannot start alone", host.status()["lobby"])
        second = launch("second")
        second.command("host")
        check(
            "Occupied port gives a clear error",
            "port" in second.status()["error"] or not second.status()["connected"],
        )
        second.command("join", address="invalid")
        check("Invalid address rejected", not second.status()["connecting"])
        second.command("join")
        host.wait(lambda s: len(s["players"]) == 2)
        second.wait(lambda s: s["connected"])
        check("Two-player lobby connected")
        third = launch("third")
        third.command("join")
        host.wait(lambda s: len(s["players"]) == 3)
        check("Three-player lobby connected")
        fourth = launch("fourth")
        fourth.command("join")
        host.wait(lambda s: len(s["players"]) == 4)
        check("Four-player lobby connected")
        extra = launch("extra")
        extra.command("join")
        extra.wait(lambda s: "full" in s["toast"])
        check(
            "Fifth player rejected without disturbing lobby",
            len(host.status()["players"]) == 4,
        )
        third.command("leave")
        host.wait(lambda s: len(s["players"]) == 3)
        third.command("join")
        host.wait(lambda s: len(s["players"]) == 4)
        check("Lobby disconnect and rejoin recovers player slot")
        host.command("begin")
        synced("state", 1)
        check("Host starts all four worlds")
        extra.command("join")
        extra.wait(lambda s: "started" in s["toast"])
        check("In-progress join rejected with recovery message")
        for guest in [second, third, fourth]:
            start = guest.status()["local_x"]
            guest.command("input", mask=2)
            guest.wait(lambda s, start=start: s["local_x"] > start + 25)
            guest.command("input", mask=0)
            check(f"{guest.name} independently moves right")
            time.sleep(0.2)
            start = guest.status()["local_x"]
            guest.command("input", mask=1)
            guest.wait(lambda s, start=start: s["local_x"] < start - 20)
            guest.command("input", mask=0)
            check(f"{guest.name} independently moves left")
        second.command("input", mask=2)
        time.sleep(0.9)
        one = second.status()["local_x"]
        time.sleep(0.3)
        check(
            "Stale input expires and stops movement",
            abs(second.status()["local_x"] - one) < 1,
        )
        second.command("input", mask=0)
        second.command("input", mask=4)
        second.wait(lambda s: s["local_y"] < 490)
        second.command("input", mask=0)
        second.command("input", mask=4)
        second.wait(
            lambda s: (
                next(p for p in s["players"] if p["number"] == s["local_number"])[
                    "jumps"
                ]
                == 0
            )
        )
        second.command("input", mask=0)
        check("Guest double jump reaches the rendered snapshot")
        host.command("camp", index=1)
        synced("weapon", "bow")
        second.command("input", mask=16)
        host.wait(lambda s: s["arrows"] > 0)
        fourth.wait(lambda s: s["arrows"] > 0)
        second.command("input", mask=0)
        check("Guest weapon is simulated on host and visible to another guest")
        for index in range(3):
            host.command("pickup", player=1, index=index)
            synced("acorns", index + 1)
        check("Guest collects all shared acorns once")
        second.command("pause")
        synced("state", 2)
        before = host.status()["elapsed"]
        second.command("input", mask=2)
        time.sleep(0.25)
        check("Guest pause freezes team timer", host.status()["elapsed"] == before)
        second.command("restart")
        check("Guest cannot restart team", host.status()["acorns"] == 3)
        host.command("gear", item="bow", enabled=False)
        synced("weapon", "")
        second.command("gear", item="bow", enabled=True)
        check("Only host changes shared gear", host.status()["weapon"] == "")
        host.command("gear", item="bow", enabled=True)
        second.command("resume")
        synced("state", 1)
        second.command("input", mask=0)
        second.command("retry")
        host.wait(lambda s: s["deaths"] >= 1)
        synced("state", 1)
        synced("acorns", 3)
        check("Guest retry returns party to shared camp and keeps pickups")
        second.command("motion", enabled=True)
        second.command("retry")
        synced("state", 3)
        synced("state", 1)
        second.wait(lambda s: all(abs(p["alpha"] - 0.75) < 0.01 for p in s["players"]))
        check("Guest gentle motion keeps protection glow steady independently of host")
        second.command("motion", enabled=False)
        host.command("gate", player=1)
        synced("state", 5)
        second.command("next")
        check("Guest cannot skip chapter", host.status()["stage"] == 0)
        host.command("next")
        synced("stage", 1)
        synced("state", 1)
        check("Host Continue loads same next chapter for party")
        host.command("level", index=2)
        synced("stage", 2)
        synced("boss_health", 3)
        check("Guardian state arrives on every client")
        host.command("level", index=19)
        synced("stage", 19)
        host.command("gate", player=2)
        synced("state", 4)
        check("Guest reaches campaign ending for whole party")
        host.command("restart")
        synced("stage", 0)
        synced("state", 1)
        synced("acorns", 0)
        synced("weapon", "")
        check("Host restart resets campaign, gear and all players")
        fourth.command("leave")
        host.wait(lambda s: len(s["players"]) == 3)
        second.wait(lambda s: len(s["players"]) == 3)
        check("Guest departure removes fox on all remaining computers")
        host.command("leave")
        for guest in [second, third]:
            guest.wait(lambda s: not s["connected"] and "host" in s["toast"])
        check("Host shutdown returns guests to usable title screen")
        second.command("host")
        fourth.command("join")
        second.wait(lambda s: len(s["players"]) == 2)
        second.command("begin")
        fourth.wait(lambda s: s["state"] == 1)
        check("Former guest can host a fresh two-player adventure")
        second.command("leave")
        extra.command("join")
        extra.wait(
            lambda s: "timed out" in s["toast"] or "Could not join" in s["toast"],
            timeout=12,
        )
        check("Unavailable host times out and offers retry")
    finally:
        for peer in peers:
            peer.close()
        (Path(directory) / "results.json").write_text(json.dumps(checks, indent=2))
    for log in Path(directory).glob("*.log"):
        content = log.read_text()
        errors = [line for line in content.splitlines() if line.startswith("ERROR:")]
        expected = (
            ["ERROR: Couldn't create an ENet host."] if log.stem == "second" else []
        )
        assert "SCRIPT ERROR" not in content and errors == expected, content[-4000:]
        assert "above the MTU" not in content, content[-4000:]

    return checks


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=ROOT / "build/lan-audit/network")
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="emberwood-lan-") as temporary:
        try:
            checks = run(temporary)
        finally:
            import shutil

            for path in Path(temporary).glob("*.log"):
                shutil.copyfile(path, args.output / path.name)
            result = Path(temporary) / "results.json"
            if result.exists():
                shutil.copyfile(result, args.output / result.name)
    print(f"PASS: {len(checks)} independent-process LAN checks.")


if __name__ == "__main__":
    main()
