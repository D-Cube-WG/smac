#!/usr/bin/env python3
from pathlib import Path
from vunit import VUnit

# ROOT points to dummy_prj (one folder above vunit/)
ROOT = Path(__file__).resolve().parent.parent
print("ROOT folder:", ROOT)

# Start VUnit
vu = VUnit.from_argv(compile_builtins=False)
print("VUnit started")

# Add the built-in VUnit library first
vu.add_vhdl_builtins()
print("VUnit built-ins added (vunit_lib)")

# Add your own library
my_lib = vu.add_library("my_lib")
print("Library added:", my_lib.name)

# Collect HDL and TB files
hdl_dir = ROOT / "hdl"
tb_dir  = ROOT / "tb"

hdl_files = [str(f.resolve()) for f in hdl_dir.glob("*.vhd")]
tb_files = (
    [str(f.resolve()) for f in tb_dir.glob("tb_smac_pi.vhd")] +
    [str(f.resolve()) for f in tb_dir.glob("pkg_aes.vhd")]
)


print("HDL files:", hdl_files)
print("Testbench files:", tb_files)

# Add HDL files to your library
if hdl_files:
    my_lib.add_source_files(hdl_files)

# Add TB files to your library (also my_lib)
if tb_files:
    my_lib.add_source_files(tb_files)

osvvm_lib = vu.add_library("osvvm")
osvvm_path = Path.home() / ".local/lib/python3.8/site-packages/vunit/vhdl/osvvm"
# Collect all OSVVM VHDL files
osvvm_files = list(osvvm_path.glob("*.vhd"))
# Remove vendor files that are NOT for ModelSim/Questa
osvvm_files = [
    f for f in osvvm_files
    if not (
        f.name.endswith("_Aldec.vhd") or
        f.name.endswith("_GHDL.vhd")
    )
]
# Add remaining files
osvvm_lib.add_source_files([str(f) for f in osvvm_files])



print("All VHDL files added")

# Run simulation
vu.main()
print("Simulation started")
