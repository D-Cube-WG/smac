#!/usr/bin/env python3
from pathlib import Path
from vunit import VUnit

OPEN_GUI = True
CLEAN_OUTPUTS = False
NON_GUI_THREADS = 2

argv = {"*"}
argv.add("--fail-fast")

if OPEN_GUI:
    argv.add("--gui")
else:
    argv.add("-p " + str(NON_GUI_THREADS))
    argv.add("--exit-0")

if CLEAN_OUTPUTS:
    argv.add("--clean")

# ROOT points to dummy_prj (one folder above vunit/)
ROOT = Path(__file__).resolve().parent.parent
print("ROOT folder:", ROOT)

# Start VUnit
vu = VUnit.from_argv(argv)
print("VUnit started")

# Add the built-in VUnit library first
vu.add_vhdl_builtins()
print("VUnit built-ins added (vunit_lib)")

# Add your own library
my_lib = vu.add_library("my_lib")
vu.add_com()
vu.add_verification_components()
print("Library added:", my_lib.name)

# Collect HDL and TB files
hdl_dir = ROOT / "hdl"
tb_dir  = ROOT / "tb"

hdl_files = [str(f.resolve()) for f in hdl_dir.glob("*.vhd")]
tb_files = (
    [str(f.resolve()) for f in tb_dir.glob("tb_smac_1_n.vhd")] +
    [str(f.resolve()) for f in tb_dir.glob("pkg_*.vhd")]
)

print("HDL files:", hdl_files)
print("Testbench files:", tb_files)

# Add HDL files to your library
if hdl_files:
    my_lib.add_source_files(hdl_files)

# Add TB files to your library (also my_lib)
if tb_files:
    my_lib.add_source_files(tb_files)















print("All VHDL files added")

# Run simulation
vu.main()
print("Simulation started")
