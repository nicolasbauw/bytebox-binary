#!/usr/bin/env python3
"""Drive a ByteBox debugging session from Python.

Starts `bytebox --debug --json` and exchanges one command for one JSON line
(`command`, `ok`, `output`, `log`, `trace`, `stop`, `regs`). The demo scenario
stops several times on a label, reads registers and memory at each stop,
measures the gap in frames and checks a simple expectation (exit status 0 or 1).

    python3 tools/debug_driver.py --snapshot prog.sna --sym prog.sym \\
        --label draw --hits 5 --watch '&a000'

Other bytebox options (--disk, --tape...) go after `--`. $BYTEBOX names the
executable (default: `bytebox` in the PATH). Needs ByteBox 2.3.
"""

import argparse
import json
import os
import subprocess
import sys


class DebugSession:
    """One `bytebox --debug --json` session: `cmd` sends a command and returns
    the decoded reply; it raises if the command fails and `check` is true."""

    def __init__(self, args):
        exe = os.environ.get("BYTEBOX", "bytebox")
        self.proc = subprocess.Popen(
            [exe, "--debug", "--json"] + args,
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
        # Lines already produced at startup (loading of the symbols).
        self.startup = []
        if "--sym" in args:
            self.startup.append(self._read())

    def _read(self):
        line = self.proc.stdout.readline()
        if not line:
            raise RuntimeError("the debug session ended")
        return json.loads(line)

    def cmd(self, line, check=True):
        self.proc.stdin.write(line + "\n")
        self.proc.stdin.flush()
        reply = self._read()
        if check and not reply["ok"]:
            raise RuntimeError(f"{line}: {reply['output'].strip()}")
        return reply

    def json(self, what):
        """`json regs|hw|sym|mem ...`: the decoded content."""
        return json.loads(self.cmd("json " + what)["output"])

    def mem(self, address, length=1):
        return self.json(f"mem {address} {length}")["bytes"]

    def close(self):
        self.proc.stdin.write("quit\n")
        self.proc.stdin.close()
        self.proc.wait()


def main():
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--snapshot")
    p.add_argument("--sym")
    p.add_argument("--label", required=True, help="where to stop")
    p.add_argument("--hits", type=int, default=5)
    p.add_argument("--watch", help="byte to read at each stop (address or symbol)")
    p.add_argument("--before", action="append", default=[],
                   help="session command run before the loop (repeatable), e.g. 'frame 150' or 'type run\\n'")
    p.add_argument("rest", nargs="*", help="other options of bytebox")
    a = p.parse_args()

    args = list(a.rest)
    if a.snapshot:
        args += ["--snapshot", a.snapshot]
    if a.sym:
        args += ["--sym", a.sym]
    s = DebugSession(args)
    try:
        for c in a.before:
            s.cmd(c)
        s.cmd(f"b {a.label}")
        rows = []
        for i in range(a.hits):
            r = s.cmd("g")
            if r["stop"] != "breakpoint":
                print(f"hit {i + 1}: not reached ({r['stop']})")
                break
            regs = r["regs"]
            watched = s.mem(a.watch)[0] if a.watch else None
            rows.append((regs["frame"], regs["pc"], regs["hl"], watched))
            print(f"hit {i + 1}: frame {regs['frame']}  PC={regs['pc']:04X}"
                  f" ({regs['symbol']})  HL={regs['hl']:04X}"
                  + (f"  ({a.watch})={watched:02X}" if a.watch else ""))
        # Measure: gap in frames between two hits.
        gaps = [b[0] - a_[0] for a_, b in zip(rows, rows[1:])]
        if gaps:
            print(f"frames between hits: {gaps}")
        # Expectation: the watched value changes from one hit to the next.
        if a.watch and len(rows) > 1:
            values = [row[3] for row in rows]
            ok = all(x != y for x, y in zip(values, values[1:]))
            print(("PASS" if ok else "FAIL") + f": ({a.watch}) changes at every hit {values}")
            if not ok:
                sys.exit(1)
    finally:
        s.close()


if __name__ == "__main__":
    main()
